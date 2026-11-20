importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDF9RSOiUkcathlfc3RwD3-l_QL_1TQSgw',
  authDomain: 'roaq-b9d7a.firebaseapp.com',
  projectId: 'roaq-b9d7a',
  storageBucket: 'roaq-b9d7a.firebasestorage.app',
  messagingSenderId: '506462734650',
  appId: '1:506462734650:web:a4d2783a8a95d3d8592803',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'إشعار جديد';
  const body = payload.notification?.body || '';
  self.registration.showNotification(title, {
    body,
    icon: '/favicon.png',
    tag: payload.data?.notification_id || 'roaq-vendor-notification',
    renotify: true,
    requireInteraction: true,
    data: payload.data || {},
  });
});
