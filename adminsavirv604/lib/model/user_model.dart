class User {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String verificationCode;
  final bool isActive;
  final String password;
  final String imageName;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.verificationCode,
    required this.isActive,
    required this.password,
    required this.imageName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final approveValue = json['users_approve'];

    return User(
      id: json['users_id']?.toString() ?? '',
      name: json['users_name']?.toString() ?? '',
      phone: json['users_phone']?.toString() ?? '',
      email: json['users_email']?.toString() ?? '',
      verificationCode: json['users_verfiycode']?.toString() ?? '',
      isActive: approveValue == 1 || approveValue == '1' || approveValue == true,
      password: json['users_password']?.toString() ?? '',
      imageName: json['users_image']?.toString() ?? '',
    );
  }

  String get imageUrl {
    if (imageName.isEmpty) return '';
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      return imageName;
    }
    return 'https://savir-technology.online/roaqv2/uploads/users/img/$imageName';
  }
}
