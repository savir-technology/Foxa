class AccountingEntry {
  String? entryId;
  String? entryDate;
  String? entryType;
  String? debit;
  String? credit;
  String? description;

  AccountingEntry({
    this.entryId,
    this.entryDate,
    this.entryType,
    this.debit,
    this.credit,
    this.description,
  });

  AccountingEntry.fromJson(Map<String, dynamic> json) {
    entryId = json['entry_id']?.toString();
    entryDate = json['entry_date'];
    entryType = json['entry_type'];
    debit = json['debit']?.toString();
    credit = json['credit']?.toString();
    description = json['description'];
  }
}
