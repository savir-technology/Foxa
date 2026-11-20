import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool? isPaid;
  bool isLoading = true;

  final String message =
      "⚠️ قم بسداد الاشتراك الشهري لتتمكن من إدارة متجرك الإلكتروني.\n\n"
      "💳 لتحويل الدفعة، استخدم الرقم التالي:\n"
      "📞 01065145794\n\n"
      "⏰ بعد الدفع، اضغط على زر *تحقق من الدفع*، وسيتم التحقق من حسابك خلال ساعة كحد أقصى.\n"
      "💬 لتسريع العملية، أرسل لقطة شاشة (Screenshot) للدفع إلى رقم:\n"
      "📱 01112608734 عبر واتساب.\n\n"
      "شكرًا لتعاونك ❤️";

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final response = await http.get(Uri.parse(
          'https://savir-technology.online/roaqv2/check_subscription.php'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isPaid = data['is_paid'] == 1;
          isLoading = false;
        });
      } else {
        throw Exception("خطأ في الاتصال بالخادم");
      }
    } catch (e) {
      setState(() {
        isPaid = false;
        isLoading = false;
      });
    }
  }

  void _verifyPayment() {
    // هنا يمكن وضع منطق التحقق الفعلي من الدفع
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلب التحقق من الدفع بنجاح ✅'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'الاشتراك الشهري',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 20,
          ),
        ),
        backgroundColor: kSurface,
        centerTitle: true,
        elevation: 0,
      ),
      body: DashboardBackground(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimary),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kGlass,
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: kGlow.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: kPrimary.withOpacity(0.08)),
                    ),
                    child: isPaid == true
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  color: Colors.green, size: 80),
                              SizedBox(height: 15),
                              Text(
                                "تم دفع الاشتراك بنجاح 🎉",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "يمكنك الآن إدارة متجرك الإلكتروني بكل حرية.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 15,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, color: kPrimary, size: 80),
                              const SizedBox(height: 15),
                              const Text(
                                "الاشتراك غير مفعل",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 14,
                                  height: 1.6,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton.icon(
                                onPressed: _verifyPayment,
                                icon: const Icon(Icons.verified_outlined,
                                    color: Colors.white),
                                label: const Text(
                                  'تحقق من الدفع',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontFamily: 'Cairo'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 12),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(kBorderRadius)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}
