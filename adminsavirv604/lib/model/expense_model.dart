class ExpenseModel {
  String? expenseId;
  String? expenseTitle;
  String? amount;
  String? expenseDate;

  ExpenseModel(
      {this.expenseId, this.expenseTitle, this.amount, this.expenseDate});

  ExpenseModel.fromJson(Map<String, dynamic> json) {
    expenseId = json['expense_id']?.toString();
    expenseTitle = json['expense_title'];
    amount = json['amount']?.toString();
    expenseDate = json['expense_date'];
  }
}
