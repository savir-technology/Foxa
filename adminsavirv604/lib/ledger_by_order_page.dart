import 'package:admin_tks/model/accounting_entry.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:flutter/material.dart';

class LedgerByOrderPage extends StatefulWidget {
  final String orderId;
  const LedgerByOrderPage({super.key, required this.orderId});

  @override
  State<LedgerByOrderPage> createState() => _LedgerByOrderPageState();
}

class _LedgerByOrderPageState extends State<LedgerByOrderPage> {
  final AccountingData api = AccountingData();
  List<AccountingEntry> entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final res = await api.getLedgerByOrder(widget.orderId);
    setState(() {
      entries = res ?? [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back,
                        size: 26,
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'قيود الطلب #${widget.orderId}',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color ??
                            Colors.black87),
                  ),
                  IconButton(
                      onPressed: fetch,
                      icon: Icon(Icons.refresh,
                          size: 26,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : entries.isEmpty
                      ? Center(
                          child: Text('لا توجد قيود لهذا الطلب',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final e = entries[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.description ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(e.entryDate ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('مدين: ${e.debit ?? '0'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      Text('دائن: ${e.credit ?? '0'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
