# خطة رفع قدرة النظام على تحمل ضغط الطلبات

## القرار المعماري

لن نقسم البيانات إلى 10 قواعد في البداية. سنبني النظام على قاعدة كتابة رئيسية،
ثم نضيف read replica للقراءات والتقارير، وبعد اختبار ضغط حقيقي فقط نقرر هل نحتاج
sharding. السبب أن `orders` و`order_items` و`vendor_orders` يجب أن تُكتب داخل
عملية واحدة متماسكة، وتقسيمها مبكرًا سيزيد احتمال عدم اتساق البيانات.

## المرحلة 0 — خط الأساس والأمان

- تشغيل الاختبارات على staging فقط باستخدام `loadtest/checkout.js`.
- قياس RPS، p95/p99، معدل الأخطاء، اتصالات MySQL، CPU، RAM، ووقت checkout.
- تغيير بيانات دخول قاعدة البيانات الموجودة في ملفات PHP فورًا.
- نقل إعدادات الاتصال إلى environment variables، مع منع ظهور الأسرار في logs.
- إضافة monitoring وتنبيهات للـ database connections والـ slow queries.

**شرط الانتقال:** اختبار 100 مستخدم ثم 1,000 مستخدم بدون فقد أو تكرار أوردر،
ومع تسجيل أرقام واضحة للأداء.

## المرحلة 1 — تحسين مسار إنشاء الطلب

- إبقاء transaction قصيرة ومخصصة للكتابة فقط.
- تنفيذ فحوصات السلة والمطعم والأسعار قبل بدء transaction كلما أمكن.
- عدم تنفيذ push notifications أو أي اتصال خارجي أثناء إنشاء الطلب.
- إضافة جدول `outbox_events`؛ يسجل الحدث داخل نفس transaction، ثم worker مستقل
  يرسل الإشعارات بعد نجاح commit.
- استخدام idempotency key لكل checkout لمنع إنشاء نفس الطلب مرتين عند إعادة المحاولة.
- مراجعة استعلامات `cart`, `orders`, `order_items`, و`vendor_orders` وإضافة indexes
  حسب نتائج `EXPLAIN` وليس بشكل عشوائي.

**شرط الانتقال:** checkout لا ينتظر Firebase أو أي خدمة خارجية، وجميع invariants
تظل صحيحة بعد اختبار burst.

## المرحلة 2 — توزيع التطبيق والقراءات

- تشغيل أكثر من PHP-FPM/Backend worker خلف Load Balancer.
- تحديد حد أقصى لاتصالات كل worker حتى لا يحدث connection storm على MySQL.
- إضافة Redis للكاش، rate limiting، وبيانات الجلسات إن لزم.
- توجيه dashboards والبحث والتقارير إلى read replica بعد التأكد من تحمل التأخير
  الزمني للنسخة.
- إبقاء checkout، الدفع، المخزون، وتغيير حالة الطلب على قاعدة الكتابة الرئيسية.

## المرحلة 3 — الاختبار التدريجي

1. 100 مستخدم متزامن.
2. 1,000 مستخدم متزامن.
3. 5,000 مستخدم متزامن.
4. 10,000 مستخدم متزامن.

بعد كل اختبار نتحقق من:

- عدم وجود duplicate orders.
- تطابق أعداد `orders`, `order_items`, و`vendor_orders`.
- عدم تحويل السلة مرتين.
- p95 وp99 ومعدل الأخطاء.
- عدم امتلاء connections أو CPU أو disk.

## المرحلة 4 — Sharding عند الحاجة فقط

إذا ظلت قاعدة الكتابة هي عنق الزجاجة بعد المراحل السابقة، نقسم حسب `vendor_id`
أو المنطقة، مع وضع الأوردر وجميع تفاصيله في نفس shard. نترك قاعدة مركزية للهوية
والإعدادات، ونبني التقارير من pipeline غير متزامن بدل queries مباشرة على 10 قواعد.

## معيار النجاح النهائي

لا نعتبر النظام جاهزًا لموجة 10,000 طلب إلا بعد نجاح اختبار staging بنفس مواصفات
الإنتاج، مع هامش أمان لا يقل عن 30% في CPU والـ connections، ووجود backup/restore
مُجرّب وخطة rollback.

## ما تم تنفيذه الآن

- Centralized database configuration through `ROAQ_DB_*` environment variables.
- Removed database credentials from the PHP connection files.
- Added `FOR UPDATE` to the open-cart read to prevent concurrent double checkout.
- Deferred vendor notification work until after the order transaction commits.
- Cached repeated `information_schema` existence checks during each PHP request.
- Added `loadtest/verify_checkout.sql` for post-burst data-integrity checks.
- Added staging-only `loadtest/prepare_staging.sql` to create disposable users
  and carts for repeatable burst tests.
- Added an opt-in notification outbox migration and worker; it remains disabled
  until staging verification is complete.
- Added `loadtest/verify_outbox.sql` to verify that the worker drains events
  without failed deliveries.
- Added a guarded `loadtest/run-staging-burst.ps1` wrapper that blocks the
  production hostname and standardizes k6 burst execution.

Before deployment, configure the variables documented in
`backend/roaq/.env.example` and rotate the previously exposed database password.
