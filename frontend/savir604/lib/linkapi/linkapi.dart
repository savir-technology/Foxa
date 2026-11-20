class AppLink {
  static const bool bannersEnabled = true;
  static const String server = 'https://savir-technology.online/roaqv2';

  static const String paymobPayment = '$server/paymob_payment.php';

//==============================={image}============================================//
  static const String imageststatic = '$server/uploud';
  static const String imagestCategories = '$server/uploud/categories';
  static const String imagestItems = '$server/uploud/items';
  static const String imagestItemsAlt = '$server/uploads/items';

//==============================={auth}============================================//
  static const String login = '$server/auth/login.php';
  static const String signup = '$server/auth/signup.php';
  static const String verifyCode = '$server/auth/verfiycode.php';
  static const String resendCode = '$server/auth/resend.php';
  static const String checkEmail = '$server/forgetpassword/checkemail.php';
  static const String verifyResetCode = '$server/forgetpassword/verfiycode.php';
  static const String resetPassword = '$server/forgetpassword/resetpassword.php';
  static const String googlePhoneLogin = '$server/auth/google_phone_login.php';
  static const String phoneCompleteProfile =
      '$server/auth/phone_complete_profile.php';

//==================================={home}========================================//
  static const String homepage = '$server/home-ecommerse/home.php';
  static const String restaurantDetails =
      '$server/home-ecommerse/restaurant_details.php';
  static const String foodItemDetails =
      '$server/home-ecommerse/food_item_details.php';

//===================================={items}======================================//
  static const String items = '$server/items/items.php';
  static const String itemImages = '$server/items/images.php';
  static const String getProductVariants =
      '$server/items/getProductVariants.php';

//========================================{favorite}=======================================//
  static const String favoriteAdd = '$server/favorite/add.php';
  static const String favoriteRemove = '$server/favorite/remove.php';
  static const String favoriteView = '$server/favorite/view.php';
  static const String deletefromfavroite =
      '$server/favorite/deletefromfavroite.php';

//=========================================={cart}===============================================//
  static const String cartadd = '$server/cart/add.php';
  static const String cartdelete = '$server/cart/delete.php';
  static const String cartview = '$server/cart/view.php';
  static const String cartgetcountitems = '$server/cart/getcountitems.php';
  static const String checkcoupon = '$server/coupon/checkcoupon.php';
  static const String coupons = '$server/coupon/list_coupons.php';
  static const String deliveryPricing = '$server/delivery/pricing.php';
  static const String platformSettings = '$server/settings/public.php';

//=========================================={search}==================================//
  static const String searchitems = '$server/items/search.php';

//====================================================================================//
  static const String checkout = '$server/orders/checkout.php';

//====================================================================================//
  static const String addressView = '$server/address/view.php';
  static const String addressAdd = '$server/address/add.php';
  static const String addressDelete = '$server/address/delete.php';

//===================================================================================//
  static const String ordersarchive = '$server/orders/archive.php';
  static const String ordersdetails = '$server/orders/details.php';
  static const String ordersdelete = '$server/orders/delete.php';
  static const String pendingorders = '$server/orders/pending.php';

  static const String notification = '$server/notification.php';
  static const String notificationMarkRead =
      '$server/notifications/mark_read.php';
  static const String notificationMarkAllRead =
      '$server/notifications/mark_all_read.php';
  static const String adsCarousel = '$server/ads/ads2.php';
  static const String ads = '$server/ads/ads.php';

  //===================================={content}======================================//
  static const String legalDocuments = '$server/content/legal_documents.php';
  static const String cookieConsent = '$server/content/cookie_consent.php';
  static const String saveCookieConsent =
      '$server/content/save_cookie_consent.php';

  //===================================================================================//
  static const String addRating = '$server/ratings/add_rating.php';
  static const String updateRating = '$server/ratings/update_rating.php';
  static const String getRatings = '$server/ratings/get_ratings.php';
  static const String getVendorRatings = '$server/ratings/vendor_ratings.php';
  static const String topRated = '$server/ratings/top_rated_items.php';
  static const String deleteRating = '$server/ratings/delete_rating.php';
  static const String addDriverRating = '$server/driver_ratings/add_rating.php';
  static const String getDriverRating = '$server/driver_ratings/get_rating.php';

  //===================================================================================//
  static const String initPayment = '$server/payments/init_payment.php';
  static const String walletStats = '$server/auth/referralStats.php';
  static const String walletConvertPoints = '$server/auth/convertPoints.php';
  static const String walletPay = '$server/auth/payWithWallet.php';

  //===================================================================================//
  static const String getVideos = '$server/videos/get_videos.php';
  static const String addLike = '$server/videos/add_like.php';
  static const String increaseView = '$server/videos/increase_view.php';
  static const String getComments = '$server/videos/get_comments.php';
  static const String addComment = '$server/videos/add_comment.php';
  static const String likeComment = '$server/videos/like_comment.php';

  static String normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    var normalized = url.trim().replaceAll('\\', '/');
    normalized = normalized.replaceFirst(
      RegExp(r'^https://savir-technology\.online/(?:savir604|savir603)/zahra'),
      '$server/',
    );
    normalized = normalized.replaceFirst(
      RegExp(r'^https://tal9in\.site/(?:savir604|Zahra_store|aqar)/zahra'),
      '$server/',
    );
    normalized = normalized.replaceFirst(
      RegExp(r'^https://aleppoeats\.com/(?:mult_venvor/savir604/zahra|zahra)'),
      '$server/',
    );
    normalized = normalized
        .replaceAll('$server//', '$server/')
        .replaceAll('/zahrauploud/', '/zahra/uploud/')
        .replaceAll('/zahrauploads/', '/zahra/uploads/');
    return normalized.replaceAll(' ', '%20');
  }

  static String resolveUrl(String? url, {String? baseUrl}) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return '';

    final normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalizeUrl(normalized);
    }

    final base = (baseUrl ?? server).trim().replaceAll(RegExp(r'/+$'), '');
    final path = normalized.replaceFirst(RegExp(r'^/+'), '');
    return normalizeUrl('$base/$path');
  }
}
