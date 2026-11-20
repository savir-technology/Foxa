// ignore_for_file: prefer_const_constructors

import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/view/screen/about_us.dart';
import 'package:tks/features/navigation/presentation/screens/driver_navigation_screen.dart';
import 'package:tks/view/screen/address/adddetails.dart';
import 'package:tks/view/screen/address/view.dart';
import 'package:tks/view/screen/auth/auth_welcome_screen.dart';
import 'package:tks/view/screen/auth/signup_screen.dart';
import 'package:tks/view/screen/auth/verify_email_screen.dart';
import 'package:tks/view/screen/auth/forgot_password_screen.dart';
import 'package:tks/view/screen/auth/user_profile_setup.dart';
import 'package:tks/view/screen/auth/google_phone_verification.dart';
import 'package:tks/view/screen/cart.dart';
import 'package:tks/view/screen/checkout.dart';
import 'package:tks/view/screen/comment_page.dart';
import 'package:tks/view/screen/homescreen.dart';
import 'package:tks/view/screen/items.dart';
import 'package:tks/view/screen/language.dart';
import 'package:tks/view/screen/order_success_screen.dart';
import 'package:tks/view/screen/order_rejected_screen.dart';
import 'package:tks/view/screen/order_chat_screen.dart';
import 'package:tks/view/screen/order_tracking_screen.dart';
import 'package:tks/view/screen/orders/details.dart';
import 'package:tks/view/screen/orders/pending.dart';
import 'package:tks/view/screen/orders_archive_view.dart';
import 'package:tks/view/screen/offers_screen.dart';
import 'package:tks/view/screen/pickup_qr_screen.dart';
import 'package:tks/view/screen/profile_page.dart';
import 'package:tks/view/screen/recipients_page.dart';
import 'package:tks/view/screen/food_item_details.dart';
import 'package:tks/view/screen/help_center_screen.dart';
import 'package:tks/view/screen/consent_management_policy_screen.dart';
import 'package:tks/view/screen/payments_and_wallet_policy_screen.dart';
import 'package:tks/view/screen/orders_for_others_policy_screen.dart';
import 'package:tks/view/screen/restaurant_details.dart';
import 'package:tks/view/screen/productdetails.dart';
import 'package:tks/view/screen/restaurant_ratings.dart';
import 'package:tks/view/screen/splash_screen.dart';
import 'package:tks/view/screen/setting.dart';
import 'package:tks/view/screen/reviews_policy_screen.dart';
import 'package:tks/view/screen/cancellation_refund_policy_screen.dart';
import 'package:tks/view/screen/prohibited_use_policy_screen.dart';
import 'package:tks/view/screen/communications_notifications_policy_screen.dart';
import 'package:tks/view/screen/select_address_map.dart';
import 'package:tks/view/screen/privacy_policy_screen.dart';
import 'package:tks/view/screen/video_feed_page.dart';
import 'package:tks/view/screen/wallet_screen.dart';
import 'package:tks/view/screen/terms_of_use_screen.dart';
import 'package:tks/view/notification/notification_page.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'view/screen/myfavorite.dart';

List<GetPage<dynamic>>? routes = [
  GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
  GetPage(name: AppRoutes.login, page: () => const AuthWelcomeScreen()),
  GetPage(name: AppRoutes.signup, page: () => const SignupScreen()),
  GetPage(name: AppRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
  GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
  GetPage(
      name: AppRoutes.googlePhoneVerification,
      page: () => const GooglePhoneVerificationScreen()),
  GetPage(
      name: AppRoutes.userProfileSetup,
      page: () => const UserProfileSetupScreen()),
  GetPage(name: AppRoutes.homepage, page: () => const HomeScreen()),
  GetPage(
      name: AppRoutes.restaurantDetails,
      page: () => const RestaurantDetailsScreen()),
  GetPage(
      name: AppRoutes.foodItemDetails,
      page: () => const FoodItemDetailsScreen()),
  GetPage(name: AppRoutes.items, page: () => const Items()),
  GetPage(name: AppRoutes.productdetails, page: () => const ProductDetails()),
  GetPage(
      name: AppRoutes.ratingPage, page: () => const RestaurantRatingsScreen()),
  GetPage(name: AppRoutes.myfavroite, page: () => const MyFavorite()),
  GetPage(name: AppRoutes.cart, page: () => Cart()),
  GetPage(name: AppRoutes.addressview, page: () => const AddressView()),
  // GetPage(name: AppRoutes.addressadd, page: () => const AddressAdd()),
  GetPage(name: AppRoutes.checkout, page: () => const Checkout()),
  GetPage(
      name: AppRoutes.selectAddressMap, page: () => const SelectAddressMap()),
  GetPage(name: AppRoutes.recipients, page: () => const RecipientsPage()),
  GetPage(name: AppRoutes.orderSuccess, page: () => const OrderSuccessScreen()),
  GetPage(
      name: AppRoutes.orderRejected, page: () => const OrderRejectedScreen()),
  GetPage(
      name: AppRoutes.orderTracking, page: () => const OrderTrackingScreen()),
  GetPage(name: '/track/:token', page: () => const OrderTrackingScreen()),
  GetPage(
    name: AppRoutes.orderChat,
    page: () {
      final args = Get.arguments;
      final order = args is OrdersModel
          ? args
          : args is Map
              ? OrdersModel.fromJson(Map<String, dynamic>.from(args))
              : OrdersModel();
      return OrderChatScreen(order: order);
    },
  ),
  GetPage(name: AppRoutes.wallet, page: () => const WalletScreen()),
  GetPage(name: AppRoutes.pickupQr, page: () => const PickupQrScreen()),
  GetPage(name: AppRoutes.offers, page: () => const OffersScreen()),
  GetPage(name: AppRoutes.helpCenter, page: () => const HelpCenterScreen()),
  GetPage(name: AppRoutes.termsOfUse, page: () => const TermsOfUseScreen()),
  GetPage(
      name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyScreen()),
  GetPage(
      name: AppRoutes.consentManagementPolicy,
      page: () => const ConsentManagementPolicyScreen()),
  GetPage(
      name: AppRoutes.paymentsAndWalletPolicy,
      page: () => const PaymentsAndWalletPolicyScreen()),
  GetPage(
      name: AppRoutes.ordersForOthersPolicy,
      page: () => const OrdersForOthersPolicyScreen()),
  GetPage(
      name: AppRoutes.reviewsPolicy, page: () => const ReviewsPolicyScreen()),
  GetPage(
      name: AppRoutes.cancellationRefundPolicy,
      page: () => const CancellationRefundPolicyScreen()),
  GetPage(
      name: AppRoutes.prohibitedUsePolicy,
      page: () => const ProhibitedUsePolicyScreen()),
  GetPage(
      name: AppRoutes.communicationsPolicy,
      page: () => const CommunicationsNotificationsPolicyScreen()),
  GetPage(name: AppRoutes.orderspending, page: () => const OrdersPending()),
  GetPage(name: AppRoutes.ordersdetails, page: () => const OrdersDetails()),
  GetPage(
      name: AppRoutes.addressadddetails, page: () => const AddressAddDetails()),
  GetPage(name: AppRoutes.aboutus, page: () => AboutPage()),
  GetPage(
    name: AppRoutes.profilepage,
    page: () {
      final args = Get.arguments;
      final id = args is Map ? int.tryParse('${args['id'] ?? 0}') ?? 0 : 0;
      return ProfilePage(userId: id);
    },
  ),
  GetPage(name: AppRoutes.set, page: () => Settings()),
  GetPage(
      name: AppRoutes.ordersarchive_page,
      page: () => const OrdersArchivePagee()),

  GetPage(name: AppRoutes.language, page: () => const Language()),
  GetPage(
      name: AppRoutes.notificationPage, page: () => const NotificationPage()),
  GetPage(name: AppRoutes.comments, page: () => CommentsPage()),
  GetPage(name: AppRoutes.video, page: () => VideoFeedPage()),
  GetPage(
      name: AppRoutes.driverNavigation,
      page: () => const DriverNavigationScreen()),
];
