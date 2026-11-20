import 'package:get/get.dart';

class DriverTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => const {
        'ar': {
          'driver_app_title': 'Jeeb',
          'order_data_unavailable': 'بيانات الطلب غير متوفرة.',
        },
        'en': {
          'driver_app_title': 'Jeeb',
          'order_data_unavailable': 'Order data is unavailable.',
        },
      };
}

String t(String arabic, String english) {
  final code = Get.locale?.languageCode.trim().toLowerCase();
  return code == 'en' ? english : _repairMojibake(arabic);
}

String tk(String key) => key.tr;

String tx(String arabic, [String? english]) {
  final repaired = _repairMojibake(arabic);
  final dictionary = _normalizedDriverEnglishByArabic;
  return t(
    repaired,
    english ??
        dictionary[repaired] ??
        _driverEnglishByArabic[arabic] ??
        repaired,
  );
}

bool get isDriverArabic => Get.locale?.languageCode.trim().toLowerCase() != 'en';

String trParam(String arabic, String english, Map<String, Object?> values) {
  var result = t(arabic, english);
  values.forEach((key, value) {
    result = result.replaceAll('{$key}', value?.toString() ?? '');
  });
  return result;
}

const Map<String, String> _driverEnglishByArabic = {
  'الرئيسية': 'Home',
  'المساعدة': 'Support',
  'الطلبات': 'Orders',
  'الإشعارات': 'Notifications',
  'المزيد': 'More',
  'الإعدادات': 'Settings',
  'تفضيلات التطبيق': 'App preferences',
  'تخصيص تجربة استخدام التطبيق': 'Customize your app experience',
  'إدارة الإشعارات والتنبيهات': 'Manage notifications and alerts',
  'الموقع والخرائط': 'Location and maps',
  'إعدادات الموقع والخرائط': 'Location and map settings',
  'اللغة': 'Language',
  'العربية': 'Arabic',
  'الوضع الليلي': 'Dark mode',
  'تشغيل أو إيقاف الوضع الليلي': 'Turn dark mode on or off',
  'توفير البيانات': 'Data saver',
  'تقليل استهلاك البيانات أثناء الاستخدام': 'Reduce data usage while using the app',
  'الاهتزاز': 'Vibration',
  'تشغيل أو إيقاف اهتزاز الجهاز': 'Enable or disable device vibration',
  'تسجيل الخروج': 'Log out',
  'في حالة الطوارئ': 'In an emergency',
  'إذا كنت في خطر أو تحتاج مساعدة فورية، تواصل مع الطوارئ المحلية.':
      'If you are in danger or need urgent help, contact local emergency services.',
  'إذا كنت في خطر أو تحتاج مساعدة فورية، يرجى الاتصال بالطوارئ المحلية.':
      'If you are in danger or need urgent help, please contact local emergency services.',
  'بدء المناوبة': 'Start shift',
  'اتصال الإنترنت': 'Internet connection',
  'متصل': 'Connected',
  'غير متصل': 'Disconnected',
  'مفعّل': 'Enabled',
  'متوقف': 'Off',
  'الحساب': 'Account',
  'مسجل الدخول': 'Signed in',
  'مطلوب تسجيل الدخول': 'Sign in required',
  'خارج وقت العمل': 'Outside working hours',
  'عند بدء المناوبة يبدأ التتبع الجغرافي ومراقبة الطلبات تلقائياً.':
      'When you start the shift, location tracking and order monitoring start automatically.',
  'لن تتمكن من بدء المناوبة إلا خلال أوقات العمل الرسمية المحددة من داش بورد المستر.':
      'You can start a shift only during the official working hours set by admin.',
  'أنت متاح': 'You are available',
  'أنت غير متاح': 'You are unavailable',
  'لا يمكن التفعيل الآن': 'Cannot activate now',
  'يمكن للإدارة إرسال الطلبات إليك الآن.': 'Admin can send orders to you now.',
  'ابدأ المناوبة للانضمام إلى الأسطول.': 'Start your shift to join the fleet.',
  'أنت خارج أوقات العمل الرسمية المحددة من داش بورد المستر.':
      'You are outside the official working hours set by admin.',
  'أوقات العمل الرسمية': 'Official working hours',
  'الملف الشخصي': 'Profile',
  'عرض وإدارة معلومات حسابك': 'View and manage your account information',
  'السائق': 'Driver',
  'غير مكتمل': 'Incomplete',
  'سائق توصيل': 'Delivery driver',
  'المركبة غير محددة': 'Vehicle not set',
  'رقم الهاتف': 'Phone number',
  'البريد الإلكتروني': 'Email',
  'المعلومات الشخصية': 'Personal information',
  'عرض وتعديل معلوماتك الشخصية': 'View and edit your personal information',
  'المستندات': 'Documents',
  'عرض وإدارة مستنداتك': 'View and manage your documents',
  'المركبة': 'Vehicle',
  'عرض معلومات مركبتك': 'View vehicle information',
  'المحفظة والأرباح': 'Wallet and earnings',
  'عرض أرباحك وعمليات السحب': 'View earnings and withdrawals',
  'تقييماتي': 'My ratings',
  'عرض تقييمات العملاء': 'View customer ratings',
  'إعدادات التطبيق والحساب': 'App and account settings',
  'الأمان': 'Security',
  'تغيير كلمة المرور وإعدادات الأمان': 'Change password and security settings',
  'تغيير لغة التطبيق': 'Change app language',
  'مركز المساعدة': 'Help center',
  'إجابات على أكثر الأسئلة شيوعًا': 'Answers to frequently asked questions',
  'خروج من حسابك': 'Sign out of your account',
  'وصل طلب جديد': 'New order arrived',
  'سيتم القبول تلقائيًا خلال الوقت المحدد': 'The order will be accepted automatically within the time limit',
  'سيتم قبول الطلب تلقائيًا خلال': 'The order will be accepted automatically in',
  'الطلب': 'Order',
  'المطعم': 'Restaurant',
  'المستلم': 'Recipient',
  'المنطقة': 'Zone',
  'المسافة': 'Distance',
  'لا يمكن رفض الطلبات في هذا التطبيق المخصص لسائقي الشركة.':
      'Orders cannot be rejected in this company driver app.',
  'قبول الآن': 'Accept now',
  'الطلب الحالي': 'Current order',
  'التوجه إلى المطعم': 'Head to restaurant',
  'الوصول إلى المطعم': 'Arrive at restaurant',
  'استلام الطلب': 'Pick up order',
  'الوصول إلى العميل': 'Arrive at customer',
  'نجاح التسليم': 'Delivery success',
  'تحرك إلى المطعم وابدأ تنفيذ الطلب بهدوء وبأقصر وقت.':
      'Move to the restaurant and start the order calmly and as quickly as possible.',
  'تأكد من استلام جميع البنود قبل التحرك للعميل.':
      'Make sure all items are picked up before heading to the customer.',
  'الآن لديك كل البيانات اللازمة للتسليم والمتابعة.':
      'You now have all details needed for delivery and follow-up.',
  'راجع بيانات العميل ثم أكمل التسليم أو التحقق.':
      'Review customer details, then complete delivery or verification.',
  'أدخل رمز التحقق أو التقط صورة واضحة عند التسليم.':
      'Enter the verification code or take a clear photo at delivery.',
  'تم إغلاق الطلب بنجاح، ويمكنك مراجعة التفاصيل لاحقًا.':
      'The order was closed successfully, and you can review the details later.',
  'عرض تفصيلي للطلب الحالي وخيارات التواصل والتنقل.':
      'Detailed view of the current order with contact and navigation options.',
  'لا يوجد طلب نشط الآن': 'There is no active order now',
  'لا يوجد طلب جديد حالياً': 'No new order right now',
  'ستظهر الطلبات الجديدة هنا فور إرسالها من الإدارة.':
      'New orders will appear here as soon as admin sends them.',
  'فتح التتبع': 'Open tracking',
  'عنوان المطعم غير متوفر': 'Restaurant address is unavailable',
  'لا يوجد هاتف': 'No phone',
  'اتصال بالمطعم': 'Call restaurant',
  'اتصال المطعم': 'Call restaurant',
  'اتصال العميل': 'Call customer',
  'التواصل السريع': 'Quick contact',
  'الدردشة الخاصة بالطلب منفصلة، ويمكنك الاتصال مباشرة بالمطعم أو العميل من هنا.':
      'Order chat is separate, and you can call the restaurant or customer directly from here.',
  'محادثة الطلب': 'Order chat',
  'تفاصيل البنود': 'Item details',
  'لا توجد بنود مفصلة لهذا الطلب.': 'There are no detailed items for this order.',
  'ملخص الطلب': 'Order summary',
  'عدد الأصناف': 'Items count',
  'قيمة الطلب': 'Order value',
  'غير متوفر': 'Unavailable',
  'غير متاح': 'Unavailable',
  'رسوم التوصيل': 'Delivery fee',
  'مجانية': 'Free',
  'المبلغ الكلي': 'Total amount',
  'توجه إلى المطعم واستلم الطلب بدقة ثم واصل الرحلة.':
      'Head to the restaurant, pick up the order carefully, then continue the trip.',
  'راجع البنود جيداً قبل تأكيد الاستلام والتحرك للعميل.':
      'Review the items carefully before confirming pickup and moving to the customer.',
  'حافظ على المتابعة وابدأ التواصل مع العميل عند الحاجة.':
      'Keep tracking and contact the customer when needed.',
  'أكمل التسليم بعد مراجعة رمز التحقق أو الصورة.':
      'Complete delivery after checking the verification code or photo.',
  'أرسل رمز التحقق أو إثبات التسليم من هذه المرحلة.':
      'Send the verification code or proof of delivery from this step.',
  'تم التسليم بنجاح، ويمكنك العودة إلى الصفحة الرئيسية.':
      'Delivery completed successfully, and you can return home.',
  'اذهب إلى المطعم': 'Go to restaurant',
  'تأكيد الاستلام': 'Confirm pickup',
  'اذهب إلى العميل': 'Go to customer',
  'إثبات التسليم': 'Proof of delivery',
  'إدخال رمز التحقق': 'Enter verification code',
  'وصلت للمطعم': 'Arrived at restaurant',
  'تم الاستلام': 'Picked up',
  'تم التسليم': 'Delivered',
  'وصلت للعميل': 'Arrived at customer',
  'إثبات بالصورة': 'Photo proof',
  'طوارئ': 'Emergency',
  'إجراءات الطلب': 'Order actions',
  'الردود السريعة': 'Quick replies',
  'سجل الطلبات': 'Orders history',
  'جميع الطلبات السابقة وتفاصيلها': 'All previous orders and their details',
  'لا توجد طلبات مكتملة': 'No completed orders',
  'ستظهر الطلبات المنتهية هنا بعد إتمامها.': 'Completed orders will appear here after delivery.',
  'مكتمل': 'Completed',
  'تم التسليم بنجاح': 'Delivered successfully',
  'سيتم الرجوع إلى الصفحة الرئيسية خلال ثوانٍ قليلة...':
      'You will return to the home page in a few seconds...',
  'العودة للصفحة الرئيسية': 'Back to home',
  'العودة إلى الصفحة الرئيسية': 'Back to home',
  'دردشة الطلب': 'Order chat',
  'هذه الصفحة مخصصة لمحادثة الطلب الحالي فقط. صفحة الدعم الفني منفصلة ويمكن فتحها من الأيقونة العلوية.':
      'This page is for the current order chat only. Support has a separate page that can be opened from the top icon.',
  'طلبات هذا الفرع فقط تظهر هنا، أما الدعم الفني فله شاشة مستقلة.':
      'Only this branch orders appear here. Support has a separate screen.',
  'رقم الطلب': 'Order number',
  'بيانات المطعم': 'Restaurant details',
  'الاسم': 'Name',
  'العنوان': 'Address',
  'الهاتف': 'Phone',
  'بيانات المستلم': 'Recipient details',
  'رسالة الإهداء': 'Gift message',
  'الملاحظات': 'Notes',
  'ملخص التسليم': 'Delivery summary',
  'الوقت المتوقع': 'Estimated time',
  'تاريخ الإنشاء': 'Created at',
  'الأسعار': 'Prices',
  'الإجمالي': 'Total',
  'تتبع': 'Track',
  'فتح الطلب': 'Open order',
  'طلب جديد': 'New order',
  'مكلف': 'Assigned',
  'في الطريق إلى المطعم': 'Heading to restaurant',
  'في المطعم': 'At restaurant',
  'في الطريق إلى العميل': 'Heading to customer',
  'وصل إلى العميل': 'Arrived at customer',
  'بانتظار رمز التحقق': 'Waiting for verification code',
  'التحقق من OTP': 'Verify OTP',
  'لقد أرسلنا رمز التحقق إلى بريدك الإلكتروني': 'We sent the verification code to your email',
  'البريد غير متاح': 'Email unavailable',
  'تعديل': 'Edit',
  'أدخل رمز التحقق المكوّن من 6 أرقام': 'Enter the 6-digit verification code',
  'تحقق': 'Verify',
  'إعادة إرسال الرمز': 'Resend code',
  'لم يصلك الرمز؟ يمكنك إعادة الإرسال الآن.': 'Did not receive the code? You can resend now.',
  'انتظر قليلاً ثم أعد المحاولة.': 'Please wait a little, then try again.',
  'إنشاء كلمة مرور قوية': 'Create a strong password',
  'هذه الكلمة ستُستخدم لاحقًا لتسجيل الدخول': 'This password will be used later to sign in',
  'شروط كلمة المرور': 'Password requirements',
  '8 أحرف على الأقل': 'At least 8 characters',
  'حرف كبير وحرف صغير': 'Uppercase and lowercase letters',
  'رقم واحد على الأقل': 'At least one number',
  'رمز خاص مثل ! @ # \$ %': 'A special symbol such as ! @ # \$ %',
  'كلمة المرور الجديدة': 'New password',
  'متابعة': 'Continue',
  'لن نُكمل التسجيل إلا بعد إدخال كلمة مرور قوية وواضحة.':
      'Registration will continue only after entering a clear strong password.',
  'إكمال البيانات الأساسية': 'Complete basic details',
  'بعدها ستنتقل مباشرة إلى الصفحة الرئيسية': 'After this, you will go directly to home',
  'اضغط لإضافة صورة': 'Tap to add a photo',
  'تأكد من وضوح الصورة': 'Make sure the photo is clear',
  'الصورة ستظهر للعميل داخل التطبيق': 'The photo will appear to the customer in the app',
  'اسم السائق': 'Driver name',
  'نوع المركبة': 'Vehicle type',
  'رقم المركبة': 'Vehicle number',
  'إكمال التسجيل': 'Complete registration',
  'بعد الإكمال سيتم توجيهك مباشرة إلى الواجهة الرئيسية.':
      'After completion, you will be redirected to the main screen.',
  'متابعة دقيقة لكل ما يحدث على الطلبات والدعم وحساب السائق.':
      'Detailed tracking for everything happening with orders, support, and your driver account.',
  'الدعم': 'Support',
  'النظام': 'System',
  'الكل': 'All',
  'فهمت': 'Got it',
  'إغلاق': 'Close',
  'جارٍ...': 'Loading...',
  'تحديد الكل': 'Mark all',
  'المقروء': 'Read',
  'تعذر تحميل الإشعارات': 'Could not load notifications',
  'تعذر تحميل الإشعارات حالياً.': 'Could not load notifications right now.',
  'لم يتم العثور على هوية السائق بعد.': 'Driver identity was not found yet.',
  'إعادة المحاولة': 'Retry',
  'لا توجد إشعارات حالياً': 'No notifications right now',
  'عندما تصل تحديثات جديدة على الطلبات أو الدعم ستظهر هنا بشكل مرتب وواضح.':
      'When new order or support updates arrive, they will appear here clearly.',
  'غير مقروء': 'Unread',
  'مقروء': 'Read',
  'الآن': 'Now',
  'مركز الدعم': 'Support center',
  'الدعم الفني': 'Technical support',
  'تعذر تحميل الدعم الفني': 'Could not load technical support',
  'تعذر تحميل الدعم الفني حالياً.': 'Could not load technical support right now.',
  'لم يتم ربط حساب السائق بعد.': 'The driver account is not linked yet.',
  'تعذر تشغيل الصوت': 'Could not play audio',
  'حاول مرة أخرى أو تأكد من اتصالك بالإنترنت.':
      'Try again or make sure you are connected to the internet.',
  'غير محددة': 'Not specified',
  'البريد': 'Email',
  'متاح الآن': 'Available now',
  'الرسائل': 'Messages',
  'غير المقروء': 'Unread',
  'ردود الإدارة': 'Admin replies',
  'رسائل صوتية': 'Voice messages',
  'قناة رسمية لمتابعة الطلبات والدعم والرسائل الصوتية بشكل واضح وسريع.':
      'An official channel for clear and fast follow-up on orders, support, and voice messages.',
  'كل الرسائل محفوظة داخل القناة الرسمية ويظهر التحديث هنا مباشرة.':
      'All messages are saved in the official channel and updates appear here directly.',
  'المسار المخصص للدعم': 'Dedicated support channel',
  'يرى فريق الدعم هذه الرسائل مباشرة ويرد عليها من نفس القناة.':
      'The support team sees these messages directly and replies in the same channel.',
  'القناة جاهزة، ويمكنك كتابة أي ملاحظة أو إرسال رسالة صوتية الآن.':
      'The channel is ready. You can type a note or send a voice message now.',
  'أحتاج مساعدة بخصوص الطلب.': 'I need help with the order.',
  'تم حل المشكلة، شكراً لكم.': 'The issue has been solved, thank you.',
  'المشكلة ما زالت موجودة، أحتاج متابعة.':
      'The issue is still there, I need follow-up.',
  'شكراً لكم على الدعم السريع.': 'Thank you for the quick support.',
  'اكتب رسالتك أو أرسل رسالة صوتية، وسيظهر الرد هنا مباشرة.':
      'Type your message or send a voice message, and the reply will appear here directly.',
  'جار تسجيل رسالة صوتية للدعم': 'Recording a support voice message',
  'الرسائل تُحفظ داخل القناة الرسمية وتظهر لفريق الدعم مباشرة.':
      'Messages are saved in the official channel and appear directly to the support team.',
  'فشل تشغيل الصوت': 'Audio playback failed',
  'تعذر تشغيل المقطع الصوتي، حاول مرة أخرى.':
      'Could not play the audio clip, please try again.',
  'للطلب الحالي فقط': 'Current order only',
  'هذه المحادثة مخصصة لتفاصيل الطلب فقط. للدعم الفني استخدم صفحة الدعم المنفصلة.':
      'This chat is only for order details. Use the separate support page for technical support.',
  'لا توجد رسائل بعد في هذه الغرفة.': 'No messages yet in this room.',
  'أنا في الطريق.': 'I am on the way.',
  'سأصل خلال دقائق.': 'I will arrive in a few minutes.',
  'وصلت للموقع.': 'I arrived at the location.',
  'لم أتمكن من الوصول.': 'I could not reach the location.',
  'بيانات السائق': 'Driver details',
  'الملف يحتاج استكمال': 'Profile needs completion',
  'الملف جاهز': 'Profile ready',
  'أحتاج مساعدة': 'I need help',
  'تم الحل': 'Solved',
  'المشكلة ما زالت': 'Still unresolved',
  'شكراً': 'Thank you',
  'تعذر تحميل الدعم': 'Could not load support',
  'ابدأ محادثة مع الدعم': 'Start a chat with support',
  'اكتب رسالتك هنا...': 'Type your message here...',
  'أنت': 'You',
  'فريق الدعم': 'Support team',
  'رسالة صوتية': 'Voice message',
  'إيقاف الصوت': 'Stop audio',
  'تشغيل الصوت': 'Play audio',
  'يناير': 'January',
  'فبراير': 'February',
  'مارس': 'March',
  'أبريل': 'April',
  'مايو': 'May',
  'يونيو': 'June',
  'يوليو': 'July',
  'أغسطس': 'August',
  'سبتمبر': 'September',
  'أكتوبر': 'October',
  'نوفمبر': 'November',
  'ديسمبر': 'December',
  'م': 'PM',
  'ص': 'AM',
  'الخريطة غير مفعلة بعد': 'Map is not enabled yet',
  'العميل': 'Customer',
  'متابعة مباشرة': 'Live follow',
  'إعادة التمركز': 'Recenter',
  'ضع MAPBOX_ACCESS_TOKEN لتفعيل الخريطة الحية.':
      'Set MAPBOX_ACCESS_TOKEN to enable the live map.',
  'بانتظار GPS': 'Waiting for GPS',
  'GPS يعمل': 'GPS active',
  'بانتظار طلب': 'Waiting for order',
  'إلى المطعم': 'To restaurant',
  'إلى المستلم': 'To recipient',
  'عند المستلم': 'At recipient',
  'بانتظار الرمز': 'Waiting for code',
  'الوصول': 'Arrival',
  'المتبقي': 'Remaining',
  'المسار': 'Route',
  'إعادة التوجيه': 'Reroute',
  'كتم الصوت': 'Mute',
  'البريد غير صحيح': 'Invalid email',
  'أدخل بريدًا إلكترونيًا صالحًا.': 'Enter a valid email address.',
  'تعذر إرسال الرمز': 'Could not send the code',
  'الرمز غير مكتمل': 'Incomplete code',
  'أدخل رمز التحقق المرسل إلى بريدك.':
      'Enter the verification code sent to your email.',
  'رمز غير صحيح': 'Incorrect code',
  'تحقق من الرمز وأعد المحاولة.': 'Check the code and try again.',
  'تعذر التحقق': 'Could not verify',
  'كلمة المرور ضعيفة': 'Weak password',
  'يجب أن تحتوي على 8 أحرف على الأقل، وحرف كبير، وحرف صغير، ورقم، ورمز.':
      'It must contain at least 8 characters, an uppercase letter, a lowercase letter, a number, and a symbol.',
  'كلمة المرور مطلوبة': 'Password is required',
  'أدخل كلمة المرور.': 'Enter your password.',
  'فشل الدخول': 'Sign-in failed',
  'البريد الإلكتروني أو كلمة المرور غير صحيحة.':
      'The email or password is incorrect.',
  'أدخل البريد الإلكتروني من جديد.': 'Enter the email again.',
  'الاسم مطلوب': 'Name is required',
  'أدخل اسم السائق.': 'Enter the driver name.',
  'رقم الهاتف غير صحيح': 'Invalid phone number',
  'أدخل رقم هاتف صالحًا.': 'Enter a valid phone number.',
  'نوع المركبة مطلوب': 'Vehicle type is required',
  'أدخل نوع المركبة.': 'Enter the vehicle type.',
  'رقم المركبة مطلوب': 'Vehicle number is required',
  'أدخل رقم المركبة.': 'Enter the vehicle number.',
  'فشل التسجيل': 'Registration failed',
  'تعذر إنشاء الحساب، حاول مرة أخرى.':
      'Could not create the account, please try again.',
  'تعذر اختيار الصورة': 'Could not choose the photo',
  'الطوارئ': 'Emergency',
  'اختر السبب وسيتم إرساله تلقائيًا إلى العميل والمطعم والمستر.':
      'Choose a reason and it will be sent automatically to the customer, restaurant, and admin.',
  'ازدحام': 'Traffic',
  'انتظار بالمطعم': 'Waiting at restaurant',
  'خطأ بالعنوان': 'Wrong address',
  'مشكلة بالمستلم': 'Recipient issue',
  'مشكلة بالمركبة': 'Vehicle issue',
  'تعذر الإرسال': 'Could not send',
  'لم يتم إرسال رسالة الطوارئ. حاول مرة أخرى.':
      'The emergency message was not sent. Try again.',
  'تم الإرسال': 'Sent',
  'تم إرسال رسالة الطوارئ إلى شات العميل والمطعم والمستر.':
      'The emergency message was sent to the customer, restaurant, and admin chat.',
  'الرمز غير جاهز': 'Code is not ready',
  'يجب تصوير الطلب أولًا قبل إدخال رمز التحقق.':
      'Take a delivery photo first before entering the verification code.',
  'اطلب من العميل الرمز المكون من 4 أرقام ثم أدخله هنا لإكمال التسليم.':
      'Ask the customer for the 4-digit code, then enter it here to complete delivery.',
  'رمز من 4 أرقام': '4-digit code',
  'إلغاء': 'Cancel',
  'تأكيد': 'Confirm',
  'فشل إثبات التسليم': 'Delivery proof failed',
  'تعذر التحقق من الرمز. تأكد من الرمز وحاول مرة أخرى.':
      'Could not verify the code. Check it and try again.',
  'في الطريق إلى المستلم': 'On the way to the recipient',
  'وصل إلى المستلم': 'Arrived at recipient',
  'لا يوجد طلب نشط': 'No active order',
  'جاهز لبدء المناوبة.': 'Ready to start the shift.',
  'جاري بدء المناوبة...': 'Starting shift...',
  'تعذر بدء المناوبة': 'Could not start shift',
  'يرجى تفعيل GPS أولاً.': 'Please enable GPS first.',
  'مطلوب إذن الموقع.': 'Location permission is required.',
  'جارٍ تجهيز بيئة العمل...': 'Preparing the workspace...',
  'لا يوجد اتصال بالإنترنت.': 'No internet connection.',
  'فعّل GPS للمتابعة.': 'Enable GPS to continue.',
  'جاري إعادة التحقق...': 'Rechecking...',
  'تم تحديد كل الإشعارات كمقروءة': 'All notifications were marked as read',
};

Map<String, String>? _normalizedDriverEnglishByArabicCache;

Map<String, String> get _normalizedDriverEnglishByArabic {
  return _normalizedDriverEnglishByArabicCache ??= {
    for (final entry in _driverEnglishByArabic.entries)
      _repairMojibake(entry.key): entry.value,
  };
}

String _repairMojibake(String value) {
  if (!RegExp('[\u00D8\u00D9\u00C3\u00C2\u00E2]').hasMatch(value)) {
    return value;
  }

  try {
    final bytes = value.codeUnits
        .map((unit) => unit <= 255 ? unit : '?'.codeUnitAt(0))
        .toList(growable: false);
    final repaired = String.fromCharCodes(bytes);
    return Uri.decodeComponent(
      repaired.runes
          .map((rune) => '%${rune.toRadixString(16).padLeft(2, '0')}')
          .join(),
    );
  } catch (_) {
    return value
        .replaceAll('\u00E2\u20AC\u00A2', '•')
        .replaceAll('\u00D8\u00A7', 'ا')
        .replaceAll('\u00D8\u00A3', 'أ')
        .replaceAll('\u00D8\u00A5', 'إ')
        .replaceAll('\u00D8\u00A2', 'آ')
        .replaceAll('\u00D8\u00A8', 'ب')
        .replaceAll('\u00D8\u00AA', 'ت')
        .replaceAll('\u00D8\u00AB', 'ث')
        .replaceAll('\u00D8\u00AC', 'ج')
        .replaceAll('\u00D8\u00AD', 'ح')
        .replaceAll('\u00D8\u00AE', 'خ')
        .replaceAll('\u00D8\u00AF', 'د')
        .replaceAll('\u00D8\u00B0', 'ذ')
        .replaceAll('\u00D8\u00B1', 'ر')
        .replaceAll('\u00D8\u00B2', 'ز')
        .replaceAll('\u00D8\u00B3', 'س')
        .replaceAll('\u00D8\u00B4', 'ش')
        .replaceAll('\u00D8\u00B5', 'ص')
        .replaceAll('\u00D8\u00B6', 'ض')
        .replaceAll('\u00D8\u00B7', 'ط')
        .replaceAll('\u00D8\u00B8', 'ظ')
        .replaceAll('\u00D8\u00B9', 'ع')
        .replaceAll('\u00D8\u00BA', 'غ')
        .replaceAll('\u00D9\u0081', 'ف')
        .replaceAll('\u00D9\u0082', 'ق')
        .replaceAll('\u00D9\u0083', 'ك')
        .replaceAll('\u00D9\u0084', 'ل')
        .replaceAll('\u00D9\u0085', 'م')
        .replaceAll('\u00D9\u0086', 'ن')
        .replaceAll('\u00D9\u0087', 'ه')
        .replaceAll('\u00D9\u0088', 'و')
        .replaceAll('\u00D9\u008A', 'ي')
        .replaceAll('\u00D9\u0089', 'ى')
        .replaceAll('\u00D8\u00A9', 'ة')
        .replaceAll('\u00D9\u008B', 'ً')
        .replaceAll('\u00D9\u0091', 'ّ')
        .replaceAll('\u00D8\u0152', '،')
        .replaceAll('\u00D8\u0178', '؟');
  }
}
