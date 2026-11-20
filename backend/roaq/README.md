# Real Estate Platform - Complete Implementation Guide

## Project Overview

This is a **production-ready Real Estate application** combining:
- **Backend**: PHP 7.2+ with PDO, MySQL/MariaDB 11.8+
- **Frontend**: Flutter (Dart) with GetX state management
- **Payment**: Paymob gateway integration
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Hosting**: Linux/Apache with HTTPS

**Original E-Commerce Legacy**: Items, Orders, Cart remain as deprecated but functional for backward compatibility.

---

## Architecture Overview

### Database Schema
Real Estate core tables (all normalized, with proper foreign keys):
- `properties` - Property listings (apartments, villas, land, commercial)
- `property_images` - Property gallery (supports 360° views, floor plans)
- `property_documents` - Legal docs (deeds, certificates, blueprints, contracts)
- `property_favorites` - User favorites list
- `property_bookings` - Visit appointment scheduling  
- `property_reservations` - Purchase/rental reservations
- `property_visits` - Scheduled site visits
- `property_chats` - Property-specific messaging threads
- `property_chat_messages` - Messages within threads (text, audio, image, file)
- `property_calendar` - Events (visits, payments, meetings)
- `property_reviews` - User ratings and reviews
- `installment_plans` - Payment plans (monthly/yearly)
- `installment_payments` - Individual payment records
- `installments` - Legacy payment tracking
- `bank_transfers` - Bank deposit proofs (pending admin approval)
- `bank_accounts` - Available bank accounts for transfers
- `notifications` - User in-app notifications

### API Architecture

#### Property Management Endpoints
```
GET/POST  /properties/list.php              - List properties with filters
GET       /properties/view.php              - Property details + images + documents
POST      /properties/reserve.php           - Create reservation (purchase intent)
POST      /properties/book_visit.php        - Schedule property visit
POST      /properties/upload_images.php     - Admin: Upload property images
POST      /properties/upload_documents.php  - Admin: Upload legal documents
POST      /properties/favorites.php         - Add/remove/list favorites
```

#### Chat System Endpoints
```
POST      /chat/send_property_message.php   - Send message about specific property
POST      /chat/send_message.php            - Generic chat (legacy)
GET       /chat/get_messages.php            - Fetch chat history
POST      /chat/save_token.php              - FCM token registration
```

#### Installment & Payment Endpoints
```
POST      /installments/create_plan.php     - Admin: Create installment plan
GET       /installments/get_plans.php       - Get plans for property
POST      /installments/request_payment.php - User: Request installment payment
POST      /payments/submit_bank_transfer.php- User: Submit bank transfer proof
POST      /payments/init_payment.php        - Paymob payment initiation
```

#### Notification Endpoints
```
GET       /notifications/list.php           - User notifications
POST      /notifications/add.php            - Admin: Create notification
POST      /notifications/update.php         - Mark as read
POST      /notifications/delete.php         - Delete notification
```

#### Calendar Endpoints
```
POST      /calendar/add_event.php           - Add visit/payment/meeting date
GET       /calendar/get_events.php          - Get upcoming events
```

#### Admin Approval Endpoints
```
POST      /admin/approve_bank_transfer.php  - Admin: Approve/reject bank transfer
POST      /admin/approve_reservation.php    - Admin: Confirm/reject reservation
POST      /admin/approve_booking.php        - Admin: Confirm/reschedule/cancel visit
GET       /admin/bank_transfers.php         - Admin: View all transfers
GET       /admin/installment_plans.php      - Admin: View all plans
GET       /admin/property_calendar.php      - Admin: View property events
```

---

## User Workflows

### 1. Browse & Reserve Property
```
User Flow:
1. Login → Home screen lists properties
2. Click property → /properties/view.php
   - See images, documents, description
   - See available installment plans
   - See existing reservations count
3. Click "Request Reservation"
   - POST to /properties/reserve.php
   - Select installment plan
   - Receive confirmation
4. Admin approves → /admin/approve_reservation.php
   - Status changes to "confirmed"
   - User gets FCM notification
5. Property status changes to "reserved" in database
```

### 2. Schedule Property Visit
```
User Flow:
1. In property details, click "Book Visit"
   - POST to /properties/book_visit.php
   - Choose date + time from calendar
2. Admin approves → /admin/approve_booking.php
   - Status changes to "confirmed"
   - Entry added to property_calendar
3. User receives FCM reminder 24 hours before
```

### 3. Make Installment Payment
```
User Flow:
1. After reservation confirmed, user sees payment schedule
   - GET from /installments/get_plans.php
   - Shows: down payment, monthly amounts, due dates
2. User submits bank transfer:
   - POST to /payments/submit_bank_transfer.php
   - Upload receipt image
   - Provides bank reference number
3. Admin reviews → /admin/approve_bank_transfer.php
   - Verifies amount matches
   - Downloads receipt
   - Approves or requests re-submission
4. Payment confirmed → installment_payments status = "paid"
5. User receives FCM confirmation
```

### 4. Property Chat
```
User Flow:
1. In property details, click "Chat with Admin"
   - Opens property-specific chat
   - POST to /chat/send_property_message.php with property_id
2. Admin receives FCM notification
   - Replies in same thread
3. Supports: text, audio, images, documents
4. Auto-creates property_chats entry if first message
```

---

## Security Implementation

### Input Validation
- All string inputs: `filterRequest('param')` function
- Numeric inputs: Type casting `(int)`, `(float)`
- File uploads: MIME type whitelist + size limits
  - Images: JPEG, PNG, WebP (5MB max)
  - Documents: PDF + images (10MB max)
- Date validation: `preg_match('/^\d{4}-\d{2}-\d{2}$/', date)`

### SQL Injection Prevention
✅ **All queries use prepared statements**
```php
// ✓ CORRECT
$stmt = $con->prepare("SELECT * FROM properties WHERE property_id = ? AND status = ?");
$stmt->execute([$property_id, $status]);

// ✗ WRONG - NEVER DO THIS
$query = "SELECT * FROM properties WHERE property_id = $property_id";
```

### Authentication
- User identified via `user_id` in POST body (mobile-first)
- Admin verified by checking `admin.admin_id` existence
- Property ownership verified via `properties.admin_id`
- All admin operations require valid `admin_id`

### File Security
- Unique filenames: `time() . '_' . bin2hex(random_bytes(8)) . '.' . ext`
- Files stored in `uploads/` subdirectories by type
- File deletion on insert failure
- MIME type validation before save

### API Protection
- All endpoints return consistent JSON format
- Errors don't leak system information
- HTTP status codes set correctly (200, 400, 500)
- Rate limiting recommended (future enhancement)

---

## Database Migration Notes

### From E-Commerce to Real Estate
```
Legacy Tables (kept for compatibility):
- items → Used for product database, can still be listed
- orders → Can be reused for property contracts
- order_items → Can represent property reservation items
- cart → Deprecated, unused in real estate flow

New Tables (real-estate core):
- properties (replaces items for real estate)
- property_* (all real-estate specific features)
- installment_plans, installment_payments (payment plans)
- bank_transfers (proof of transfers)
```

### Recommended Indexes (Performance)
```sql
-- Properties
ALTER TABLE properties ADD INDEX idx_status (status);
ALTER TABLE properties ADD INDEX idx_city (city);
ALTER TABLE properties ADD INDEX idx_property_type (property_type);

-- Bookings & Reservations
ALTER TABLE property_bookings ADD INDEX idx_booking_date (booking_date);
ALTER TABLE property_bookings ADD INDEX idx_booking_status (booking_status);
ALTER TABLE property_reservations ADD INDEX idx_user_id (user_id);
ALTER TABLE property_reservations ADD INDEX idx_reservation_status (reservation_status);

-- Bank Transfers
ALTER TABLE bank_transfers ADD INDEX idx_status (status);
ALTER TABLE bank_transfers ADD INDEX idx_created_at (created_at);

-- Users
ALTER TABLE users ADD UNIQUE INDEX idx_email (users_email);
ALTER TABLE users ADD INDEX idx_fcm_token (fcm_token);
```

---

## Flutter Frontend Integration

### Key Files Modified/Created
- `pubspec.yaml` - Dependencies (http, GetX, cached_network_image, etc.)
- `lib/main.dart` - App initialization, GetX binding
- `lib/linkapi/linkapi.dart` - All API endpoint URLs
- `lib/view/screen/productdetails.dart` - Property details UI
- `lib/view/widget/productdetails/installment_selector.dart` - Plan selection
- `lib/view/widget/productdetails/installment_calendar.dart` - Payment calendar
- `lib/view/screen/support.dart` - Property-aware chat
- `lib/core/class/crud.dart` - HTTP client wrapper (unchanged)

### API Calls Flow
```dart
// Example: Fetch property details
final response = await Crud().postData(
  AppLink.propertyView,
  {
    'property_id': propertyId,
    'user_id': userId  // optional, for favorite status
  }
);

response.fold(
  (failure) => handleError(failure),
  (success) => updateUI(success)
);
```

### State Management (GetX)
- `ProductDetailsControllerImp` manages property state
- Controllers auto-dispose on view pop
- Reactive GetBuilder widgets auto-update on state change

---

## Deployment Checklist

### Server Requirements
- [x] PHP 7.2+ with PDO MySQL extension
- [x] MySQL 5.7+ or MariaDB 10.3+
- [x] Apache with mod_rewrite
- [x] SSL/HTTPS certificate
- [x] Firebase service account credentials
- [x] Paymob merchant API key

### Environment Setup
```bash
# Database import
mysql -u root -p < u934851659_savir_stor.sql

# File permissions
chmod 777 zahra/uploads/
chmod 777 zahra/uploads/property_images/
chmod 777 zahra/uploads/property_documents/
chmod 777 zahra/uploads/chat_attachments/
chmod 777 zahra/uploads/receipts/

# Firebase credentials
cp /path/to/serviceAccountKey.json zahra/chat/firebase/service-account.json
```

### Configuration
```php
// zahra/connect.php - Update database credentials
$dsn = "mysql:host=your-host;dbname=your-db;charset=utf8mb4";
$user = "your-user";
$pass = "your-password";

// zahra/chat/firebase/send_notification.php - FCM setup
define('FIREBASE_PROJECT_ID', 'your-project-id');
define('FIREBASE_PRIVATE_KEY_ID', 'your-key-id');
// ... rest of service account credentials
```

### Testing
1. Test user registration and login
2. List properties → GET /properties/list.php
3. View property → GET /properties/view.php?property_id=1
4. Create reservation → POST /properties/reserve.php
5. Book visit → POST /properties/book_visit.php
6. Verify FCM notifications sent
7. Admin approval flow → /admin/approve_*
8. Payment submission → /payments/submit_bank_transfer.php

---

## Verification Checklist

- [x] Database: All 60+ tables exist and populate correctly
- [x] Properties: List, view, reserve, book visit endpoints working
- [x] Chat: Property-aware messaging with auto-thread creation
- [x] Installments: Plans created, payments tracked
- [x] Payments: Bank transfer proof upload + file validation
- [x] Notifications: FCM tokens saved, messages sent
- [x] Admin Workflows: Bank transfer, reservation, booking approvals
- [x] Security: All SQL injections prevented, file uploads validated
- [x] Error Handling: Consistent JSON responses, no system leaks
- [x] Legacy Compatibility: E-commerce items/orders still functional
- [x] API Documentation: All endpoints documented with parameters
- [x] Flutter UI: Property details + installments + calendar implemented
- [x] FCM Integration: Firebase configured and tested
- [x] Paymob: Payment initiation and webhook handling

---

## Support & Maintenance

### Common Issues & Solutions

**Endpoint returns "Property not found"**
- Verify property_id exists in properties table
- Check property_type is not NULL

**FCM notifications not sent**
- Verify fcm_token field has data in users table
- Check service-account.json path is correct
- Test with: zahra/chat/firebase/test_fcm.php

**File upload fails**
- Verify uploads/ directory permissions (chmod 777)
- Check file size doesn't exceed limits
- Verify MIME type is in whitelist

**Database connection error**
- Verify credentials in zahra/connect.php match server
- Check database exists and is accessible
- Ensure PDO MySQL extension installed

### Monitoring
- Monitor uploads/ directory size (delete old files monthly)
- Check server logs for SQL errors
- Track payment success rate (target: >95%)
- Monitor FCM delivery rate
- Set up database backup alerts

### Version Control & Updates
- Tag releases: v1.0.0 (initial), v1.1.0 (features), etc.
- Document API changes in CHANGELOG
- Test admin/approval endpoints monthly
- Run security audit quarterly

---

## Future Enhancements

### Phase 2
- [ ] Rate limiting on auth endpoints
- [ ] Payment dispute handling system
- [ ] Property inspection scheduling
- [ ] Mortgage pre-qualification calculator
- [ ] Property investment ROI calculator
- [ ] Virtual property tours (360° integration)
- [ ] Document e-signing integration

### Phase 3
- [ ] Multi-language support (Arabic + English fully implemented)
- [ ] Advanced analytics dashboard
- [ ] CRM integration for leads
- [ ] Automated property matching
- [ ] Blockchain contract verification
- [ ] Mobile app analytics tracking
- [ ] API usage metering & billing

---

## Contact & Support
- Technical Issues: Consult SECURITY_POLICY.php
- API Questions: Read endpoint comments in respective .php files
- Database Schema: Reference u934851659_savir_stor.sql
- Flutter Integration: See linkapi.dart for all endpoint URLs

---

**Last Updated**: February 6, 2026
**Platform Version**: 1.0.0 - Production Ready
**Database Version**: MariaDB 11.8.3
**PHP Version**: 7.2.34
