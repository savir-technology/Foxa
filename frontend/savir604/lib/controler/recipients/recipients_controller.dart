import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/recipient_local_service.dart';
import 'package:tks/data/datasource/model/recipient_model.dart';

bool _recipientArabic() => (Get.locale?.languageCode ?? 'ar') == 'ar';

String _rt(String arabic, String english) =>
    _recipientArabic() ? arabic : english;

class RecipientsController extends GetxController {
  RecipientsController({RecipientLocalService? localService})
      : _localService = localService ?? RecipientLocalService();

  final RecipientLocalService _localService;
  final List<RecipientModel> recipients = <RecipientModel>[];

  bool get hasRecipients => recipients.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadRecipients();
  }

  void loadRecipients() {
    recipients
      ..clear()
      ..addAll(_localService.loadRecipients());
    update();
  }

  Future<void> saveRecipient(RecipientModel recipient) async {
    final index = recipients.indexWhere((item) => item.id == recipient.id);
    if (index >= 0) {
      recipients[index] = recipient;
    } else {
      recipients.insert(0, recipient);
    }
    await _localService.saveRecipients(recipients);
    update();
  }

  Future<void> deleteRecipient(String recipientId) async {
    recipients.removeWhere((item) => item.id == recipientId);
    await _localService.saveRecipients(recipients);
    update();
  }

  Future<void> openRecipientEditor({
    RecipientModel? initialRecipient,
    bool popWithSelection = false,
  }) async {
    double? selectedLatitude = initialRecipient?.latitude;
    double? selectedLongitude = initialRecipient?.longitude;

    final labelController =
        TextEditingController(text: initialRecipient?.label ?? '');
    final nameController =
        TextEditingController(text: initialRecipient?.name ?? '');
    final phoneController =
        TextEditingController(text: initialRecipient?.phone ?? '');
    final addressNameController =
        TextEditingController(text: initialRecipient?.addressName ?? '');
    final addressLineController =
        TextEditingController(text: initialRecipient?.addressLine ?? '');
    final noteController =
        TextEditingController(text: initialRecipient?.locationNote ?? '');
    final buildingController =
        TextEditingController(text: initialRecipient?.building ?? '');
    final floorController =
        TextEditingController(text: initialRecipient?.floor ?? '');

    await Get.bottomSheet<void>(
      _RecipientEditorSheet(
        title: initialRecipient == null
            ? _rt('إضافة مستلم', 'Add recipient')
            : _rt('تعديل مستلم', 'Edit recipient'),
        labelController: labelController,
        nameController: nameController,
        phoneController: phoneController,
        addressNameController: addressNameController,
        addressLineController: addressLineController,
        noteController: noteController,
        buildingController: buildingController,
        floorController: floorController,
        initialLatitude: initialRecipient?.latitude,
        initialLongitude: initialRecipient?.longitude,
        initialPlaceName: initialRecipient?.addressName ?? '',
        initialAddressLine: initialRecipient?.addressLine ?? '',
        onMapSelectionChanged: (selection) {
          selectedLatitude = double.tryParse('${selection['latitude'] ?? ''}');
          selectedLongitude =
              double.tryParse('${selection['longitude'] ?? ''}');
        },
        onSave: () async {
          if (labelController.text.trim().isEmpty ||
              nameController.text.trim().isEmpty ||
              phoneController.text.trim().isEmpty ||
              addressNameController.text.trim().isEmpty ||
              addressLineController.text.trim().isEmpty) {
            Get.snackbar(
              _rt('بيانات ناقصة', 'Missing details'),
              _rt(
                'يرجى إكمال بيانات المستلم المطلوبة.',
                'Please complete the required recipient fields.',
              ),
            );
            return;
          }

          if (selectedLatitude == null || selectedLongitude == null) {
            Get.snackbar(
              _rt('الموقع مطلوب', 'Location required'),
              _rt(
                'يرجى اختيار موقع المستلم من الخريطة قبل الحفظ.',
                'Please choose the recipient location from the map before saving.',
              ),
            );
            return;
          }

          final recipient = RecipientModel(
            id: initialRecipient?.id ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            label: labelController.text.trim(),
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            addressName: addressNameController.text.trim(),
            addressLine: addressLineController.text.trim(),
            locationNote: noteController.text.trim(),
            building: buildingController.text.trim(),
            floor: floorController.text.trim(),
            latitude: selectedLatitude,
            longitude: selectedLongitude,
            createdAt: initialRecipient?.createdAt ?? DateTime.now(),
          );

          await saveRecipient(recipient);
          Get.back();
          if (popWithSelection) {
            Get.back(result: recipient.toJson());
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
    );
  }
}

class _RecipientEditorSheet extends StatefulWidget {
  const _RecipientEditorSheet({
    required this.title,
    required this.labelController,
    required this.nameController,
    required this.phoneController,
    required this.addressNameController,
    required this.addressLineController,
    required this.noteController,
    required this.buildingController,
    required this.floorController,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.initialPlaceName,
    required this.initialAddressLine,
    required this.onMapSelectionChanged,
    required this.onSave,
  });

  final String title;
  final TextEditingController labelController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressNameController;
  final TextEditingController addressLineController;
  final TextEditingController noteController;
  final TextEditingController buildingController;
  final TextEditingController floorController;
  final double? initialLatitude;
  final double? initialLongitude;
  final String initialPlaceName;
  final String initialAddressLine;
  final ValueChanged<Map<String, dynamic>> onMapSelectionChanged;
  final VoidCallback onSave;

  @override
  State<_RecipientEditorSheet> createState() => _RecipientEditorSheetState();
}

class _RecipientEditorSheetState extends State<_RecipientEditorSheet> {
  final ScrollController _scrollController = ScrollController();
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedPlaceName = '';
  String _selectedAddressLine = '';
  String _selectedCity = '';
  bool _isPickingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _selectedPlaceName = widget.initialPlaceName;
    _selectedAddressLine = widget.initialAddressLine;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMapSelection =>
      _selectedLatitude != null && _selectedLongitude != null;

  String get _mapPreviewLabel {
    final parts = <String>[
      if (_selectedPlaceName.trim().isNotEmpty) _selectedPlaceName.trim(),
      if (_selectedAddressLine.trim().isNotEmpty) _selectedAddressLine.trim(),
      if (_selectedCity.trim().isNotEmpty) _selectedCity.trim(),
    ];
    if (parts.isEmpty) {
      return _rt(
        'اضغط زر الخريطة لاختيار الموقع',
        'Tap the map button to choose a location',
      );
    }
    return parts.join(' - ');
  }

  String get _mapPreviewCoordinates {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      return '';
    }
    return '${_selectedLatitude!.toStringAsFixed(5)}, ${_selectedLongitude!.toStringAsFixed(5)}';
  }

  Future<void> _pickLocationOnMap() async {
    if (_isPickingLocation) {
      return;
    }
    setState(() {
      _isPickingLocation = true;
    });

    final result = await Get.toNamed(
      AppRoutes.selectAddressMap,
      arguments: {
        'mode': 'recipient',
        'country': 'EG',
        'title': _rt('اختيار موقع المستلم', 'Choose recipient location'),
        'hint_title': _rt('اختر موقع المستلم', 'Choose the recipient location'),
        'hint_body': _rt(
          'اضغط على الخريطة وسنملأ تفاصيل العنوان للمستلم.',
          'Tap on the map and we will fill the address details for the recipient.',
        ),
        'confirm_label': _rt('استخدام الموقع', 'Use location'),
        'return_only': true,
        if (_selectedLatitude != null) 'initial_latitude': _selectedLatitude,
        if (_selectedLongitude != null) 'initial_longitude': _selectedLongitude,
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isPickingLocation = false;
    });

    if (result is! Map) {
      return;
    }

    final selection = Map<String, dynamic>.from(result);
    final latitude = double.tryParse('${selection['latitude'] ?? ''}');
    final longitude = double.tryParse('${selection['longitude'] ?? ''}');
    final placeName =
        '${selection['place_name'] ?? selection['address_name'] ?? ''}'.trim();
    final addressLine = '${selection['address_line'] ?? ''}'.trim();
    final city = '${selection['city'] ?? ''}'.trim();
    final street = '${selection['street'] ?? ''}'.trim();

    if (latitude != null && longitude != null) {
      setState(() {
        _selectedLatitude = latitude;
        _selectedLongitude = longitude;
        _selectedPlaceName = placeName;
        _selectedAddressLine = addressLine;
        _selectedCity = city;
      });
    }

    widget.onMapSelectionChanged({
      'latitude': latitude,
      'longitude': longitude,
      'place_name': placeName,
      'address_line': addressLine,
      'city': city,
      'street': street,
    });

    if (widget.addressNameController.text.trim().isEmpty &&
        placeName.isNotEmpty) {
      widget.addressNameController.text = placeName;
    }
    if (widget.addressLineController.text.trim().isEmpty) {
      if (addressLine.isNotEmpty) {
        widget.addressLineController.text = addressLine;
      } else if (street.isNotEmpty) {
        widget.addressLineController.text = street;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = _recipientArabic();

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.88,
            widthFactor: 1,
            child: Material(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: Get.back,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rt('بيانات المستلم', 'Recipient details'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _RecipientField(
                                  controller: widget.labelController,
                                  label: _rt('الاسم المختصر', 'Label'),
                                  hint: _rt(
                                    'أمي، أخي، بيت العائلة...',
                                    'Mom, brother, family house...',
                                  ),
                                  icon: Icons.bookmark_border_rounded,
                                ),
                                const SizedBox(height: 12),
                                _RecipientField(
                                  controller: widget.nameController,
                                  label: _rt('اسم المستلم', 'Recipient name'),
                                  hint: _rt('الاسم الكامل', 'Full name'),
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                                _RecipientField(
                                  controller: widget.phoneController,
                                  label: _rt('رقم الهاتف', 'Phone number'),
                                  hint: '+49...',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                _RecipientField(
                                  controller: widget.addressNameController,
                                  label: _rt('اسم الموقع', 'Location name'),
                                  hint: _rt(
                                    'المنزل، المكتب، بيت العائلة...',
                                    'Home, office, family house...',
                                  ),
                                  icon: Icons.place_outlined,
                                ),
                                const SizedBox(height: 12),
                                _RecipientField(
                                  controller: widget.addressLineController,
                                  label: _rt('العنوان', 'Address'),
                                  hint: _rt(
                                    'الحي، الشارع، أقرب علامة',
                                    'District, street, nearest landmark',
                                  ),
                                  icon: Icons.map_outlined,
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isPickingLocation
                                        ? null
                                        : _pickLocationOnMap,
                                    icon: _isPickingLocation
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.map_outlined),
                                    label: Text(
                                      _hasMapSelection
                                          ? _rt(
                                              'تغيير الموقع على الخريطة',
                                              'Change map location',
                                            )
                                          : _rt(
                                              'اختيار الموقع من الخريطة',
                                              'Pick location on map',
                                            ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(54),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasMapSelection) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _mapPreviewLabel,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (_mapPreviewCoordinates
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _mapPreviewCoordinates,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RecipientField(
                                        controller: widget.buildingController,
                                        label: _rt('البناء', 'Building'),
                                        hint: _rt('اختياري', 'Optional'),
                                        icon: Icons.apartment_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _RecipientField(
                                        controller: widget.floorController,
                                        label: _rt('الطابق', 'Floor'),
                                        hint: _rt('اختياري', 'Optional'),
                                        icon: Icons.stairs_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _RecipientField(
                                  controller: widget.noteController,
                                  label: _rt('ملاحظة الموقع', 'Location note'),
                                  hint: _rt(
                                    'مثال: خلف المخبز، بجانب الصيدلية...',
                                    'Example: behind the bakery, next to the pharmacy...',
                                  ),
                                  icon: Icons.edit_location_alt_outlined,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _hasMapSelection ? widget.onSave : null,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      _rt('حفظ المستلم', 'Save recipient'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _RecipientField extends StatelessWidget {
  const _RecipientField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      scrollPadding: const EdgeInsets.only(bottom: 140),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
