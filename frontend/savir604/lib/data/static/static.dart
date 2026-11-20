import 'package:tks/core/constant/imsgesassets.dart';
import 'package:tks/data/datasource/model/OnBordingmodel.dart';

List<OnBordingmodels> buildOnboardingList() {
  return [
    OnBordingmodels(
      title: 'Send food to your friends and family in Egypt with ease',
      body:
          'Choose the restaurant and meal from anywhere in the world, then send the order directly to your loved ones in Egypt.',
      badge: 'Send to loved ones',
      highlights: const [
        'Multi restaurant',
        'Clear flow',
        'Fast ordering',
      ],
      images: AppImageAsset.onBoardingImageOne,
    ),
    OnBordingmodels(
      title: 'Track the order live until it arrives',
      body:
          'Follow every step from restaurant acceptance to driver arrival and final delivery proof.',
      badge: 'Live tracking',
      highlights: const [
        'Live map',
        'Clear statuses',
        'Share tracking',
      ],
      images: AppImageAsset.onBoardingImageTwo,
    ),
    OnBordingmodels(
      title: 'Pay through secure payment gateways',
      body:
          'Use multiple payment methods, attach a gift note, and pay securely before sending the order.',
      badge: 'Secure payment',
      highlights: const [
        'Wallet and coupons',
        'Gift note',
        'Multi gateway',
      ],
      images: AppImageAsset.onBoardingImageThree,
    ),
  ];
}
