import 'dart:async';
import 'dart:convert';
import 'package:admin_tks/linkchat.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_chat_room.dart';

class AdminChatUsers extends StatefulWidget {
  const AdminChatUsers({super.key});

  @override
  State<AdminChatUsers> createState() => _AdminChatUsersState();
}

class _AdminChatUsersState extends State<AdminChatUsers> {
  List users = [];
  Timer? _refreshTimer;

  /// جلب المستخدمين من السيرفر
  Future<void> getUsers() async {
    try {
      var res = await http.get(Uri.parse(AppLink.getUsers));
      var data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() => users = data['data']);
      } else {
        setState(() => users = []);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// حذف محادثة المستخدم
  Future<void> deleteChat(int userId) async {
    try {
      var res = await http.post(
        Uri.parse(AppLink.deleteChat),
        body: {'user_id': userId.toString()},
      );
      var data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم حذف المحادثة بنجاح")),
        );
        getUsers(); // تحديث القائمة بعد الحذف
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getUsers();

    // تحديث تلقائي كل 3 ثواني
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      getUsers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final primaryLight = theme.primaryColorLight;
    final bodyColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final smallColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary, // use theme primary for header
        title: Text(
          "رسائل المستخدمين",
          style: TextStyle(
              color: theme.appBarTheme.foregroundColor ?? Colors.white,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: users.isEmpty
          ? Center(
              child: Text(
                "لا توجد محادثات بعد",
                style: TextStyle(color: smallColor),
              ),
            )
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, i) {
                final user = users[i];
                final userId = int.tryParse(user['user_id'].toString()) ?? 0;
                final userName = user['users_name'] ?? "مستخدم بدون اسم";

                return Dismissible(
                  key: Key(userId.toString()),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    color: theme.colorScheme.error,
                    padding: const EdgeInsets.only(left: 20),
                    child: Icon(Icons.delete,
                        color:
                            theme.appBarTheme.foregroundColor ?? Colors.white),
                  ),
                  onDismissed: (direction) {
                    deleteChat(userId);
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 2,
                    color: theme.cardColor,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            primary.withOpacity(0.15), // light primary
                        child: Icon(Icons.person, color: primary),
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bodyColor,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "اضغط لفتح المحادثة",
                        style: TextStyle(color: smallColor, fontSize: 13),
                      ),
                      trailing: Icon(Icons.chat_bubble_outline, color: primary),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminChatRoom(userId: userId),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
