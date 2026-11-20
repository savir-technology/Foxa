import 'package:admin_tks/model/user_model.dart';
import 'package:admin_tks/remote/user_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserData()..fetchUsers(),
      child: Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          title: const Text(
            'المستخدمون',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: kSurface,
          elevation: 0,
          centerTitle: true,
        ),
        body: DashboardBackground(
          child: Consumer<UserData>(
            builder: (context, userData, child) {
              if (userData.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: kPrimary),
                );
              }

              if (userData.errorMessage != null) {
                return _UsersMessageState(
                  icon: Icons.cloud_off_rounded,
                  message: userData.errorMessage!,
                  actionLabel: 'إعادة المحاولة',
                  onPressed: userData.fetchUsers,
                );
              }

              if (userData.users.isEmpty) {
                return _UsersMessageState(
                  icon: Icons.people_outline_rounded,
                  message: 'لا يوجد مستخدمون لعرضهم حالياً.',
                  actionLabel: 'تحديث',
                  onPressed: userData.fetchUsers,
                );
              }

              final activeCount =
                  userData.users.where((user) => user.isActive).length;
              final inactiveCount = userData.users.length - activeCount;

              return RefreshIndicator(
                color: kPrimary,
                onRefresh: userData.fetchUsers,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _UsersHeroCard(
                      totalUsers: userData.users.length,
                      activeUsers: activeCount,
                      inactiveUsers: inactiveCount,
                    ),
                    const SizedBox(height: 18),
                    ...userData.users.map(
                      (user) => _UserCard(
                        user: user,
                        onToggleStatus: (nextValue) async {
                          try {
                            await userData.updateUserStatus(
                              userId: user.id,
                              isActive: nextValue,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nextValue
                                      ? 'تم تفعيل حساب ${user.name}'
                                      : 'تم حظر حساب ${user.name}',
                                ),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('فشل تحديث حالة المستخدم: $error'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UsersHeroCard extends StatelessWidget {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;

  const _UsersHeroCard({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لوحة المستخدمين',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'متابعة الحسابات وصور المستخدمين وحالة التفعيل والحظر من مكان واحد.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                label: 'إجمالي المستخدمين',
                value: totalUsers.toString(),
              ),
              _StatChip(
                label: 'الحسابات النشطة',
                value: activeUsers.toString(),
              ),
              _StatChip(
                label: 'الحسابات المحظورة أو غير النشطة',
                value: inactiveUsers.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final Future<void> Function(bool nextValue) onToggleStatus;

  const _UserCard({
    required this.user,
    required this.onToggleStatus,
  });

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final letters = parts.take(2).map((e) => e.substring(0, 1)).join();
    return letters.isEmpty ? 'U' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isActive ? const Color(0xFF16A34A) : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(user: user, fallbackText: _initials(user.name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'بدون اسم' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isEmpty ? 'لا يوجد بريد إلكتروني' : user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            user.isActive ? 'نشط' : 'محظور / غير نشط',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: kStroke),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoTile(
                icon: Icons.phone_in_talk_rounded,
                label: 'رقم الهاتف',
                value: user.phone,
              ),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                label: 'كود التحقق',
                value: user.verificationCode,
              ),
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'رقم المستخدم',
                value: user.id,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: user.isActive ? null : () => onToggleStatus(true),
                icon: const Icon(Icons.verified_rounded),
                label: const Text('تفعيل يدوي'),
              ),
              OutlinedButton.icon(
                onPressed: user.isActive ? () => onToggleStatus(false) : null,
                icon: const Icon(Icons.block_rounded),
                label: const Text('حظر المستخدم'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final User user;
  final String fallbackText;

  const _UserAvatar({
    required this.user,
    required this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: user.imageUrl.isEmpty
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: user.imageUrl.isEmpty ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: user.imageUrl.isEmpty
          ? Text(
              fallbackText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            )
          : Image.network(
              user.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: kPrimary,
                  alignment: Alignment.center,
                  child: Text(
                    fallbackText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: kPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersMessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final Future<void> Function() onPressed;

  const _UsersMessageState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kGlass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kPrimary.withValues(alpha: 0.10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: kPrimary),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 15,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(
                actionLabel,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
