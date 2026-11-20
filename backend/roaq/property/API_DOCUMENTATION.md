# 📋 Property System Backend APIs Documentation

## 🎯 نظرة عامة
هذه الوثيقة تشرح جميع الـ APIs الجديدة المضافة لنظام العقارات والاستثمارات.

---

## 📍 Base URL
```
https://savir-technology.online/roaqv2/property/api/
```

---

## 🏠 **1. جلب تفاصيل العقار مع الصور والفيديوهات**

### GET `get_item_with_media.php`

**الوصف:** جلب بيانات العقار الكاملة مع جميع الصور والفيديوهات والخطط الاستثمارية

**المعاملات:**
- `item_id` (int) - معرف العقار - **مطلوب**

**مثال الطلب:**
```
GET /property/api/get_item_with_media.php?item_id=127
```

**الاستجابة الناجحة:**
```json
{
  "status": "success",
  "item": {
    "items_id": 127,
    "items_name_en": "Property Name",
    "items_name_ar": "اسم العقار",
    "items_price": 70000,
    "items_discount": 10,
    "property_rooms": 3,
    "property_bathrooms": 2,
    "property_floor": 5,
    "property_area": 150.50
  },
  "images": [
    {
      "media_id": 1,
      "media_url": "/uploads/items_media/img1.jpg",
      "media_type": "image",
      "is_primary": 1,
      "sort_order": 0
    }
  ],
  "videos": [
    {
      "media_id": 2,
      "media_url": "https://youtube.com/...",
      "media_type": "video"
    }
  ],
  "plans": [
    {
      "plan_id": 1,
      "plan_type": "monthly",
      "duration_months": 16,
      "total_price": 1000000,
      "down_payment": 0,
      "installment_amount": 12000
    }
  ],
  "property_specs": {
    "rooms": 3,
    "bathrooms": 2,
    "floor": 5,
    "area": 150.50
  }
}
```

---

## 💰 **2. جلب استثمارات المستخدم**

### GET `get_my_investments.php`

**الوصف:** جلب جميع العقود والاستثمارات النشطة للمستخدم مع الملخصات

**المعاملات:**
- `user_id` (int) - معرف المستخدم - **مطلوب**

**مثال الطلب:**
```
GET /property/api/get_my_investments.php?user_id=104
```

**الاستجابة الناجحة:**
```json
{
  "status": "success",
  "data": [
    {
      "contract_id": 1,
      "user_id": 104,
      "users_name": "islam ashraf",
      "property_name": "Property Name",
      "plan_type": "monthly",
      "total_price": 1000000,
      "down_payment": 0,
      "total_installments": 16,
      "paid_installments": 1,
      "remaining_installments": 15
    }
  ],
  "summary": {
    "total_investment": 1000000,
    "total_paid": 12000,
    "total_remaining": 988000,
    "contracts_count": 1
  }
}
```

---

## 🎬 **3. جلب فيديوهات العقار**

### GET `get_item_videos.php`

**الوصف:** جلب جميع الفيديوهات المرتبطة بعقار معين مع معلومات المستخدم والتعليقات

**المعاملات:**
- `item_id` (int) - معرف العقار - **مطلوب**
- `page` (int) - رقم الصفحة - **اختياري** (افتراضي: 1)
- `limit` (int) - عدد النتائج - **اختياري** (افتراضي: 10)

**مثال الطلب:**
```
GET /property/api/get_item_videos.php?item_id=127&page=1&limit=5
```

**الاستجابة الناجحة:**
```json
{
  "status": "success",
  "data": [
    {
      "video_id": 1,
      "video_title": "Tour of the property",
      "video_desc": "Complete tour",
      "video_url": "https://youtube.com/...",
      "video_thumbnail": "thumb.jpg",
      "video_views": 150,
      "video_likes": 20,
      "users_name": "Admin",
      "comments_count": 5,
      "video_date": "2026-02-13 10:00:00"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 5,
    "total": 12,
    "pages": 3
  }
}
```

---

## 📢 **4. جلب الإعلانات مع ربط العقارات**

### GET `get_ads2_with_items.php`

**الوصف:** جلب جميع الإعلانات مع بيانات العقار المرتبط بكل إعلان

**المعاملات:**
لا توجد معاملات مطلوبة

**مثال الطلب:**
```
GET /property/api/get_ads2_with_items.php
```

**الاستجابة الناجحة:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "image_url": "/uploads/ads/ad1.jpg",
      "created_at": "2026-02-13 10:00:00",
      "item_id": 127,
      "items_id": 127,
      "items_name_en": "Property Name",
      "items_name_ar": "اسم العقار",
      "items_price": 70000,
      "property_rooms": 3,
      "property_bathrooms": 2,
      "property_floor": 5
    }
  ],
  "count": 1
}
```

---

## 🖼️ **5. رفع صور وفيديوهات العقار**

### POST `upload_item_media.php`

**الوصف:** رفع صور أو فيديوهات جديدة لعقار (للمسؤول فقط)

**المعاملات:**
- `item_id` (int) - معرف العقار - **مطلوب**
- `media_type` (string) - نوع الوسيط: 'image' أو 'video' - **مطلوب**
- `image` (file) - ملف الصورة لـ media_type = image - **مطلوب للصور**
- `video_url` (string) - رابط الفيديو لـ media_type = video - **مطلوب للفيديوهات**
- `is_primary` (int) - هل هي الصورة الرئيسية (0/1) - **اختياري**
- `sort_order` (int) - ترتيب العرض - **اختياري**

**مثال الطلب (للصور):**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/upload_item_media.php \
  -F "item_id=127" \
  -F "media_type=image" \
  -F "image=@path/to/image.jpg" \
  -F "is_primary=1" \
  -F "sort_order=0"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Media uploaded successfully",
  "media_id": 5,
  "media_url": "/uploads/items_media/item_127_1707810000_1234.jpg"
}
```

---

## 📋 **6. جلب تفاصيل الأقساط لخطة معينة**

### GET `get_plan_installments.php`

**الوصف:** جلب جميع الأقساط لخطة معينة مع الإحصائيات

**المعاملات:**
- `user_id` (int) - معرف المستخدم - **مطلوب**
- `plan_id` (int) - معرف الخطة - **مطلوب**

**مثال الطلب:**
```
GET /property/api/get_plan_installments.php?user_id=104&plan_id=1
```

**الاستجابة الناجحة:**
```json
{
  "status": "success",
  "plan": {
    "plan_id": 1,
    "item_id": 127,
    "plan_type": "monthly",
    "duration_months": 16,
    "total_price": 1000000,
    "down_payment": 0,
    "installment_amount": 12000
  },
  "installments": [
    {
      "installment_id": 31,
      "due_date": "2026-02-01",
      "amount": 12000,
      "status": "paid",
      "paid_at": "2026-02-11 11:47:00"
    },
    {
      "installment_id": 32,
      "due_date": "2026-03-01",
      "amount": 12000,
      "status": "pending",
      "paid_at": null
    }
  ],
  "statistics": {
    "total_installments": 16,
    "paid_installments": 1,
    "pending_installments": 15,
    "late_installments": 0,
    "total_paid_amount": 12000,
    "remaining_amount": 988000
  }
}
```

---

## ✍️ **7. إنشاء عقد جديد (عقد قطاع الاستثمار)**

### POST `create_contract.php`

**الوصف:** إنشاء عقد جديد للعميل مع إنشاء الأقساط تلقائياً

**المعاملات:**
- `user_id` (int) - معرف المستخدم - **مطلوب**
- `item_id` (int) - معرف العقار - **مطلوب**
- `plan_id` (int) - معرف الخطة - **مطلوب**

**مثال الطلب:**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/create_contract.php \
  -d "user_id=104&item_id=127&plan_id=1"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Contract created successfully",
  "contract_id": 2,
  "total_installments": 16
}
```

---

## 📝 **8. إنشاء خطة استثمار جديدة**

### POST `create_plan.php`

**الوصف:** إنشاء خطة استثمار جديدة لعقار (للمسؤول فقط)

**المعاملات:**
- `item_id` (int) - معرف العقار - **مطلوب**
- `plan_type` (string) - نوع الخطة: 'monthly' / 'yearly' / 'Quarterly' - **مطلوب**
- `duration_months` (int) - مدة الخطة بالأشهر - **مطلوب**
- `total_price` (float) - السعر الإجمالي - **مطلوب**
- `down_payment` (float) - الدفعة الأولى/الأولية - **مطلوب**
- `start_date` (string) - تاريخ البداية بصيغة YYYY-MM-DD - **مطلوب**

**مثال الطلب:**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/create_plan.php \
  -d "item_id=127&plan_type=monthly&duration_months=16&total_price=1000000&down_payment=0&start_date=2026-02-01"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Plan created successfully",
  "plan_id": 3,
  "plan": {
    "plan_id": 3,
    "plan_type": "monthly",
    "duration_months": 16,
    "total_price": 1000000,
    "down_payment": 0,
    "installment_amount": 62500
  }
}
```

---

## 🎥 **9. إضافة فيديو جديد للعقار**

### POST `add_video.php`

**الوصف:** إضافة فيديو جديد مرتبط بعقار معين

**المعاملات:**
- `video_title` (string) - عنوان الفيديو - **مطلوب**
- `video_url` (string) - رابط الفيديو - **مطلوب**
- `video_product_id` (int) - معرف العقار - **مطلوب**
- `video_desc` (string) - وصف الفيديو - **اختياري**
- `video_thumbnail` (string) - رابط الصورة المصغرة - **اختياري**
- `video_userid` (int) - معرف المستخدم الذي رفع الفيديو - **اختياري**

**مثال الطلب:**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/add_video.php \
  -d "video_title=Property Tour&video_url=https://youtube.com/...&video_product_id=127"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Video added successfully",
  "video_id": 5,
  "video": {
    "video_id": 5,
    "video_title": "Property Tour",
    "video_url": "https://youtube.com/...",
    "video_product_id": 127,
    "video_date": "2026-02-13 10:00:00"
  }
}
```

---

## 📢 **10. إنشاء إعلان جديد**

### POST `create_ad2.php`

**الوصف:** إنشاء إعلان جديد مرتبط بعقار (للمسؤول فقط)

**المعاملات:**
- `image_url` (string) - رابط صورة الإعلان - **مطلوب**
- `item_id` (int) - معرف العقار - **اختياري**

**مثال الطلب:**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/create_ad2.php \
  -d "image_url=/uploads/ads/ad1.jpg&item_id=127"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Ad created successfully",
  "ad_id": 2,
  "ad": {
    "id": 2,
    "image_url": "/uploads/ads/ad1.jpg",
    "item_id": 127,
    "created_at": "2026-02-13 10:00:00"
  }
}
```

---

## 🔄 **11. تحديث ربط الإعلان بعقار**

### POST `update_ad_item.php`

**الوصف:** تحديث الإعلان لربطه بعقار معين (للمسؤول فقط)

**المعاملات:**
- `ad_id` (int) - معرف الإعلان - **مطلوب**
- `item_id` (int) - معرف العقار الجديد - **مطلوب**

**مثال الطلب:**
```bash
curl -X POST https://savir-technology.online/roaqv2/property/api/update_ad_item.php \
  -d "ad_id=1&item_id=127"
```

**الاستجابة:**
```json
{
  "status": "success",
  "message": "Ad updated successfully"
}
```

---

## 🔐 الأمان والملاحظات

1. **التحقق من الوصول**: جميع العمليات تتطلب التحقق من هوية المستخدم
2. **التحقق من الصيغة**: جميع المدخلات يتم التحقق منها والتصفية
3. **معالجة الأخطاء**: جميع الأخطاء يتم تسجيلها في السجلات
4. **أنواع الملفات**: الصور المقبولة: jpg, jpeg, png, gif, webp
5. **الترميز**: جميع البيانات بصيغة UTF-8

---

## 📊 حالات الاستجابة

- `success`: العملية نجحت
- `failure`: فشل في جلب البيانات
- `error`: حدث خطأ في الخادم

---

**آخر تحديث:** 13 فبراير 2026
