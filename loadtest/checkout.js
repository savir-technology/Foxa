import http from 'k6/http';
import { check } from 'k6';
import exec from 'k6/execution';

let loggedFailures = 0;

// Each virtual user must have one prepared cart on the test database.
// The endpoint reads the cart from the database and deletes it after checkout.
const baseUrl = (__ENV.BASE_URL || '').replace(/\/+$/, '');
const userStartId = Number(__ENV.USER_START_ID || 0);
const vus = Number(__ENV.VUS || 100);
const timeout = __ENV.HTTP_TIMEOUT || '30s';
const loadMode = (__ENV.LOAD_MODE || 'burst').toLowerCase();
const totalRequests = Number(__ENV.TOTAL_REQUESTS || 1000);
const rateDuration = __ENV.RATE_DURATION || '30m';

if (!baseUrl) {
  throw new Error('BASE_URL is required, for example https://staging.example.com/roaqv2');
}
if (!userStartId) {
  throw new Error('USER_START_ID is required and must point to seeded test users');
}
// Block only the exact live host. A staging subdomain such as
// staging.savir-technology.online must remain allowed.
const isLiveProduction = /^https?:\/\/(www\.)?savir-technology\.online(?:\/|$)/i.test(baseUrl);
if (isLiveProduction && __ENV.ALLOW_PRODUCTION !== 'YES') {
  throw new Error('Production URL blocked. Use staging, or explicitly set ALLOW_PRODUCTION=YES.');
}

export const options = {
  scenarios: {
    ...(loadMode === 'rate'
      ? {
          checkout_rate: {
            executor: 'constant-arrival-rate',
            rate: totalRequests,
            timeUnit: rateDuration,
            duration: rateDuration,
            preAllocatedVUs: Math.max(1, vus),
            maxVUs: Math.max(Math.max(1, vus), Number(__ENV.MAX_VUS || 50)),
          },
        }
      : {
          checkout_burst: {
            executor: 'per-vu-iterations',
            vus,
            iterations: 1,
            maxDuration: __ENV.MAX_DURATION || '5m',
          },
        }),
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<3000', 'p(99)<8000'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  // __VU is 1-based. Use a different prepared account for every request.
  const iterationIndex = loadMode === 'rate'
    ? exec.scenario.iterationInTest
    : __VU - 1;
  const userId = userStartId + iterationIndex;
  const endpoint = `${baseUrl}/orders/checkout.php`;

  // Keep this payload aligned with frontend/savir604's CheckoutController.
  // The cart itself is seeded server-side for userId.
  const payload = {
    usersid: String(userId),
    addressid: '0',
    orderstype: '1', // pickup: avoids real delivery-zone calculations
    pricedelivery: '0',
    couponid: '',
    paymentmethod: '0', // cash on delivery; no real payment gateway call
    recipient_name: 'Load Test User',
    recipient_phone: `010000${String(userId).padStart(5, '0')}`,
    recipient_label: 'Load Test',
    recipient_address_name: 'Test Store',
    recipient_address_line: 'Load test address',
    recipient_location_note: '',
    recipient_building: '',
    recipient_floor: '',
    recipient_lat: '',
    recipient_lng: '',
    address_lat: '',
    address_lng: '',
    delivery_latitude: '',
    delivery_longitude: '',
    delivery_address: '',
    order_mode: 'asap',
    scheduled_for: '',
    gift_message: '',
    delivery_note: 'Automated load-test order',
  };

  const response = http.post(endpoint, payload, {
    headers: {
      Accept: 'application/json',
      'X-Load-Test': 'checkout-burst',
    },
    timeout,
    tags: { endpoint: 'checkout' },
  });

  let body = {};
  const rawBody = String(response.body || '').slice(0, 500);
  try {
    body = response.json();
  } catch (_) {
    // The check below records the malformed response as a failed request.
  }

  // Keep diagnostics bounded: enough to identify rate limiting, database
  // errors, or application validation failures without flooding the console.
  if (response.status < 200 || response.status >= 300 || body.status !== 'success') {
    if (__VU === 1 && loggedFailures < 20) {
      loggedFailures += 1;
      console.error(JSON.stringify({
        loadtest_failure: loggedFailures,
        user_id: userId,
        status: response.status,
        error: response.error || '',
        body: Object.keys(body).length > 0 ? body : rawBody,
        headers: {
          server: response.headers.Server || '',
          content_type: response.headers['Content-Type'] || '',
          retry_after: response.headers['Retry-After'] || '',
          cf_ray: response.headers['CF-Ray'] || '',
        },
      }));
    }
  }

  check(response, {
    'HTTP status is 2xx': (r) => r.status >= 200 && r.status < 300,
    'checkout returned success': () => body.status === 'success',
    'order id returned': () => Number(body.order_id || 0) > 0,
  });
}
