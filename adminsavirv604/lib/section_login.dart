import 'package:flutter/material.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';

class SectionLoginPage extends StatefulWidget {
  final String title;
  final Widget page;
  const SectionLoginPage({super.key, required this.title, required this.page});

  @override
  State<SectionLoginPage> createState() => _SectionLoginPageState();
}

class _SectionLoginPageState extends State<SectionLoginPage> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  String? _error;

  final Map<String, Map<String, String>> _creds = {
    "المحادثات": {"username": "user1", "password": "20032003"},
    "المنتجات": {"username": "user2", "password": "20002000"},
    "إضافة منتج": {"username": "user2", "password": "20002000"},
    "الأقسام": {"username": "user2", "password": "20002000"},
    "إضافة قسم": {"username": "user2", "password": "20002000"},
    "الفديوهات": {"username": "user3", "password": "4444344"},
    "إحصائيات": {"username": "user4", "password": "444555"},
    "إحصائيات الاهتمام": {"username": "user4", "password": "444555"},
    "إحصائيات المخزون": {"username": "user4", "password": "444555"},
    "احصائيات المخزون": {"username": "user4", "password": "444555"},
  };

  @override
  void initState() {
    super.initState();
    if (!_creds.containsKey(widget.title)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => widget.page));
      });
    }
  }

  void _tryLogin() {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();
    final required = _creds[widget.title];
    if (required == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => widget.page));
      return;
    }
    if (u == required['username'] && p == required['password']) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => widget.page));
    } else {
      setState(() => _error = "اسم المستخدم أو كلمة المرور غير صحيحة");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text('تسجيل دخول - ${widget.title}',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: 20,
            )),
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: DashboardBackground(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 420,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('يرجى إدخال بيانات الدخول',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                        fontFamily: 'Cairo')),
                const SizedBox(height: 12),
                TextField(
                  controller: _userCtrl,
                  style:
                      const TextStyle(color: kTextPrimary, fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle:
                        TextStyle(color: kTextSecondary, fontFamily: 'Cairo'),
                    filled: true,
                    fillColor: kSurface,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary, width: 2),
                      borderRadius:
                          BorderRadius.all(Radius.circular(kBorderRadius)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary, width: 1.2),
                      borderRadius:
                          BorderRadius.all(Radius.circular(kBorderRadius)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  style:
                      const TextStyle(color: kTextPrimary, fontFamily: 'Cairo'),
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    labelStyle:
                        TextStyle(color: kTextSecondary, fontFamily: 'Cairo'),
                    filled: true,
                    fillColor: kSurface,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary, width: 2),
                      borderRadius:
                          BorderRadius.all(Radius.circular(kBorderRadius)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kPrimary, width: 1.2),
                      borderRadius:
                          BorderRadius.all(Radius.circular(kBorderRadius)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.red, fontFamily: 'Cairo')),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء',
                            style: TextStyle(fontFamily: 'Cairo'))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: _tryLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(kBorderRadius)),
                          ),
                        ),
                        child: const Text('دخول',
                            style: TextStyle(
                                color: Colors.white, fontFamily: 'Cairo')))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
