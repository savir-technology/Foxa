class support_model {
  String? complaintId;
  String? userName;
  String? userPhone;
  String? userEmail;
  String? complaintDescription;
  String? submissionDate;

  support_model(
      {this.complaintId,
      this.userName,
      this.userPhone,
      this.userEmail,
      this.complaintDescription,
      this.submissionDate});

  support_model.fromJson(Map<String, dynamic> json) {
    complaintId = json['complaint_id'].toString();
    userName = json['user_name'].toString();
    userPhone = json['user_phone'].toString();
    userEmail = json['user_email'].toString();
    complaintDescription = json['complaint_description'].toString();
    submissionDate = json['submission_date'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['complaint_id'] = complaintId;
    data['user_name'] = userName;
    data['user_phone'] = userPhone;
    data['user_email'] = userEmail;
    data['complaint_description'] = complaintDescription;
    data['submission_date'] = submissionDate;
    return data;
  }
}
