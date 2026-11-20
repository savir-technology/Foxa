// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterLegalContentWorkspace extends StatefulWidget {
  const MasterLegalContentWorkspace({
    super.key,
    required this.api,
    required this.token,
    required this.canEdit,
  });

  final MasterAuthApiService api;
  final String token;
  final bool canEdit;

  @override
  State<MasterLegalContentWorkspace> createState() =>
      _MasterLegalContentWorkspaceState();
}

class _MasterLegalContentWorkspaceState
    extends State<MasterLegalContentWorkspace> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api._fetchMasterLegalContentRaw(widget.token);
  }

  void _reload() {
    setState(() {
      _future = widget.api._fetchMasterLegalContentRaw(widget.token);
    });
  }

  List<Map<String, dynamic>> _list(Map<String, dynamic> raw, String key) {
    final value = raw[key];
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _save(
    String entity,
    Map<String, dynamic> data, [
    int? id,
  ]) async {
    try {
      await widget.api._saveMasterLegalContent(
        widget.token,
        entity: entity,
        id: id,
        data: data,
      );
      if (mounted) {
        _showMasterSnack(context, 'تم حفظ التعديل في قاعدة البيانات');
      }
      _reload();
    } catch (error) {
      if (mounted) _showMasterSnack(context, 'تعذر الحفظ: $error');
    }
  }

  Future<void> _delete(String entity, int id) async {
    try {
      await widget.api._deleteMasterLegalContent(
        widget.token,
        entity: entity,
        id: id,
      );
      if (mounted) {
        _showMasterSnack(context, 'تم إيقاف العنصر مع الحفاظ على السجل');
      }
      _reload();
    } catch (error) {
      if (mounted) _showMasterSnack(context, 'تعذر الإيقاف: $error');
    }
  }

  Future<void> _editLegacy(
    String entity,
    Map<String, dynamic>? existing,
  ) async {
    final fields = <String, TextEditingController>{};
    final names = entity == 'document'
        ? [
            'document_key',
            'document_type',
            'title_ar',
            'title_en',
            'subtitle_ar',
            'subtitle_en',
            'content_ar',
            'content_en',
            'accent_color',
            'hero_icon',
            'sort_order',
          ]
        : entity == 'cookie_profile'
        ? [
            'profile_key',
            'title_ar',
            'title_en',
            'subtitle_ar',
            'subtitle_en',
            'body_ar',
            'body_en',
            'accept_all_label_ar',
            'accept_all_label_en',
            'customize_label_ar',
            'customize_label_en',
            'reject_optional_label_ar',
            'reject_optional_label_en',
            'footer_note_ar',
            'footer_note_en',
            'version_label',
            'accent_color',
          ]
        : [
            'profile_key',
            'option_key',
            'title_ar',
            'title_en',
            'description_ar',
            'description_en',
            'badge_ar',
            'badge_en',
            'icon_name',
            'badge_color',
            'sort_order',
          ];
    for (final name in names) {
      fields[name] = TextEditingController(
        text: (existing?[name] ?? '').toString(),
      );
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'إضافة عنصر قانوني' : 'تعديل العنصر'),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final entry in fields.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: entry.value,
                      minLines:
                          entry.key.contains('content') ||
                              entry.key.contains('body') ||
                              entry.key.contains('description') ||
                              entry.key.contains('subtitle') ||
                              entry.key.contains('footer')
                          ? 3
                          : 1,
                      maxLines:
                          entry.key.contains('content') ||
                              entry.key.contains('body') ||
                              entry.key.contains('description') ||
                              entry.key.contains('subtitle') ||
                              entry.key.contains('footer')
                          ? 6
                          : 1,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (result == true) {
      final data = <String, dynamic>{
        for (final entry in fields.entries) entry.key: entry.value.text.trim(),
      };
      if (entity == 'document') {
        data['summary_ar'] = <String>[];
        data['summary_en'] = <String>[];
      } else if (entity == 'cookie_option') {
        data['preference_keys'] = <String>[];
        data['is_locked'] = existing?['is_locked'] ?? 0;
        data['default_enabled'] = existing?['default_enabled'] ?? 0;
      }
      await _save(
        entity,
        data,
        existing == null
            ? null
            : _toInt(
                existing[entity == 'document'
                    ? 'document_id'
                    : entity == 'cookie_profile'
                    ? 'profile_id'
                    : 'option_id'],
              ),
      );
    }
    for (final controller in fields.values) {
      controller.dispose();
    }
  }

  Future<void> _edit(String entity, Map<String, dynamic>? existing) async {
    final names = entity == 'document'
        ? <String>[
            'document_key',
            'document_type',
            'title_ar',
            'title_en',
            'subtitle_ar',
            'subtitle_en',
            'content_ar',
            'content_en',
            'accent_color',
            'hero_icon',
            'sort_order',
          ]
        : entity == 'cookie_profile'
        ? <String>[
            'profile_key',
            'title_ar',
            'title_en',
            'subtitle_ar',
            'subtitle_en',
            'body_ar',
            'body_en',
            'version_label',
            'accent_color',
          ]
        : <String>[
            'profile_key',
            'option_key',
            'title_ar',
            'title_en',
            'description_ar',
            'description_en',
            'badge_ar',
            'badge_en',
            'icon_name',
            'badge_color',
            'sort_order',
          ];
    final controllers = <String, TextEditingController>{
      for (final key in names)
        key: TextEditingController(text: (existing?[key] ?? '').toString()),
    };
    bool longField(String key) =>
        key.contains('content') ||
        key.contains('body') ||
        key.contains('description') ||
        key.contains('subtitle');
    String label(String key) =>
        <String, String>{
          'document_key': 'المعرّف الداخلي',
          'document_type': 'نوع الوثيقة',
          'profile_key': 'معرّف الملف',
          'option_key': 'معرّف الخيار',
          'title_ar': 'العنوان بالعربية',
          'title_en': 'العنوان بالإنجليزية',
          'subtitle_ar': 'الوصف المختصر بالعربية',
          'subtitle_en': 'الوصف المختصر بالإنجليزية',
          'content_ar': 'المحتوى الكامل بالعربية',
          'content_en': 'المحتوى الكامل بالإنجليزية',
          'body_ar': 'نص السياسة بالعربية',
          'body_en': 'نص السياسة بالإنجليزية',
          'description_ar': 'الوصف بالعربية',
          'description_en': 'الوصف بالإنجليزية',
          'badge_ar': 'الشارة بالعربية',
          'badge_en': 'الشارة بالإنجليزية',
          'version_label': 'رقم الإصدار',
          'accent_color': 'لون التمييز',
          'badge_color': 'لون الشارة',
          'hero_icon': 'أيقونة الوثيقة',
          'icon_name': 'أيقونة الخيار',
          'sort_order': 'ترتيب العرض',
        }[key] ??
        key;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: _kLightBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: SizedBox(
          width: 920,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kAccentGreen.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.edit_document,
                        color: _kAccentGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            existing == null
                                ? 'إضافة محتوى جديد'
                                : 'تعديل المحتوى',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: _kDeepGreen,
                            ),
                          ),
                          Text(
                            entity == 'document'
                                ? 'وثيقة قانونية'
                                : entity == 'cookie_profile'
                                ? 'ملف موافقة الكوكيز'
                                : 'خيار كوكيز',
                            style: const TextStyle(color: Color(0xFF667085)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: const Color(0x160B1020)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final entry in controllers.entries)
                      SizedBox(
                        width: longField(entry.key) ? 860 : 420,
                        child: TextField(
                          controller: entry.value,
                          minLines: longField(entry.key) ? 4 : 1,
                          maxLines: longField(entry.key) ? 8 : 1,
                          textDirection: entry.key.endsWith('_en')
                              ? TextDirection.ltr
                              : TextDirection.rtl,
                          decoration: InputDecoration(
                            labelText: label(entry.key),
                            hintText: 'اكتب ${label(entry.key)}',
                            prefixIcon: Icon(
                              longField(entry.key)
                                  ? Icons.notes_rounded
                                  : Icons.tune_rounded,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('حفظ التعديلات'),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('إلغاء'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true) {
      final data = <String, dynamic>{
        for (final entry in controllers.entries)
          entry.key: entry.value.text.trim(),
      };
      if (entity == 'document') {
        data['summary_ar'] = <String>[];
        data['summary_en'] = <String>[];
      }
      if (entity == 'cookie_option') {
        data['preference_keys'] = <String>[];
        data['is_locked'] = existing?['is_locked'] ?? 0;
        data['default_enabled'] = existing?['default_enabled'] ?? 0;
      }
      await _save(
        entity,
        data,
        existing == null
            ? null
            : _toInt(
                existing[entity == 'document'
                    ? 'document_id'
                    : entity == 'cookie_profile'
                    ? 'profile_id'
                    : 'option_id'],
              ),
      );
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _section(
    String title,
    String entity,
    List<Map<String, dynamic>> rows,
    String nameKey,
    String idKey,
  ) {
    return _AccessPanel(
      title: title,
      subtitle:
          'إدارة مباشرة للمحتوى المنشور في تطبيق المستخدم مع صلاحية مسؤول الأمن والماستر فقط',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: widget.canEdit ? () => _edit(entity, null) : null,
              icon: const Icon(Icons.add),
              label: const Text('إضافة جديد'),
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Text('لا توجد بيانات', textAlign: TextAlign.center)
          else
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(
                    (row[nameKey] ??
                            row['document_key'] ??
                            row['option_key'] ??
                            '')
                        .toString(),
                  ),
                  subtitle: Text(
                    'الحالة: ${(row['is_active'] ?? 0).toString()}  •  المعرّف: ${(row[idKey] ?? '').toString()}',
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        onPressed: widget.canEdit
                            ? () => _edit(entity, row)
                            : null,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: widget.canEdit
                            ? () => _delete(entity, _toInt(row[idKey]))
                            : null,
                        icon: const Icon(
                          Icons.archive_outlined,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _OperationsDataErrorState(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }
        final raw = snapshot.data ?? const <String, dynamic>{};
        final documents = _list(raw, 'documents');
        final profiles = _list(raw, 'cookie_profiles');
        final options = _list(raw, 'cookie_options');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AccessPanel(
              title: 'الأمن والشؤون القانونية',
              subtitle:
                  'السياسات، الشروط، الخصوصية، وملفات تعريف الارتباط المنشورة للمستخدمين',
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(
                    Icons.policy_outlined,
                    size: 34,
                    color: _kPrimaryGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'صلاحية التعديل محمية من الخادم وتتاح للماستر ومسؤول الأمن والشؤون القانونية فقط. سجل موافقات المستخدمين للعرض الإحصائي ولا يتم حذفه.',
                    ),
                  ),
                  IconButton(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section(
              'السياسات والملفات القانونية',
              'document',
              documents,
              'title_ar',
              'document_id',
            ),
            const SizedBox(height: 12),
            _section(
              'ملف موافقة الكوكيز',
              'cookie_profile',
              profiles,
              'title_ar',
              'profile_id',
            ),
            const SizedBox(height: 12),
            _section(
              'خيارات الكوكيز',
              'cookie_option',
              options,
              'title_ar',
              'option_id',
            ),
            const SizedBox(height: 12),
            _AccessPanel(
              title: 'سجل الموافقات',
              subtitle:
                  'إحصاءات للرقابة فقط دون كشف installation_key أو preferences للمستخدمين',
              child: Text(
                (raw['consent_stats'] as List?)
                        ?.map(
                          (e) =>
                              '${e['profile_key']} / ${e['consent_mode']}: ${e['total']}',
                        )
                        .join('\n') ??
                    'لا توجد سجلات',
              ),
            ),
          ],
        );
      },
    );
  }
}
