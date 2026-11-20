import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  List<dynamic> _adsList = [];
  String? _currentAdImageUrl;
  String? _currentAdLinkUrl;
  int _currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAds();
    _scheduleAdSwitch();
  }

  Future<void> _fetchAds() async {
    try {
      final response = await http.get(
        Uri.parse('https://savir-technology.online/roaqv2/ads/ads.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _adsList = data;
            _currentAdImageUrl = _adsList[0]['image_url']?.toString();
            _currentAdLinkUrl = _adsList[0]['link_url']
                ?.toString()
                .replaceAll(RegExp(r'[\r\n]'), '');
          });
        }
      } else {
        setState(() {
          _adsList = [];
          _currentAdImageUrl = null;
          _currentAdLinkUrl = null;
        });
      }
    } catch (_) {
      setState(() {
        _adsList = [];
        _currentAdImageUrl = null;
        _currentAdLinkUrl = null;
      });
    }
  }

  void _scheduleAdSwitch() {
    if (_adsList.isNotEmpty) {
      Future.delayed(const Duration(seconds: 10), () {
        if (!mounted || _adsList.isEmpty) return;

        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % _adsList.length;
          _currentAdImageUrl =
              _adsList[_currentAdIndex]['image_url']?.toString();
          _currentAdLinkUrl = _adsList[_currentAdIndex]['link_url']
              ?.toString()
              .replaceAll(RegExp(r'[\r\n]'), '');
        });

        _scheduleAdSwitch();
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يمكن فتح الرابط')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_adsList.isNotEmpty &&
        _currentAdImageUrl != null &&
        _currentAdLinkUrl != null) {
      return GestureDetector(
        onTap: () => _launchURL(_currentAdLinkUrl!),
        child: Container(
          width: screenWidth,
          height: 110,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: kGlass,
            borderRadius: BorderRadius.circular(kBorderRadius),
            boxShadow: [
              BoxShadow(
                color: kGlow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kBorderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  imageUrl: _currentAdImageUrl!,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 16,
                    ),
                    color: kBackground.withValues(alpha: 0.45),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.open_in_new, color: kPrimary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'اضغط لزيارة الرابط',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: kPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
      );
    }

    return Container(
      width: screenWidth,
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kGlow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
      ),
      child: const Center(
        child: Text(
          'لا يوجد إعلان حالياً',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kTextSecondary,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}

class Ads2Page extends StatefulWidget {
  const Ads2Page({super.key});

  @override
  State<Ads2Page> createState() => _Ads2PageState();
}

class _Ads2PageState extends State<Ads2Page> {
  static const String _baseUrl = 'https://savir-technology.online/roaqv2/ads';
  static const String _ads2Url = '$_baseUrl/ads2.php';
  static const String _addUrl = '$_baseUrl/add_ads2.php';
  static const String _updateUrl = '$_baseUrl/update_ads2.php';
  static const String _deleteUrl = '$_baseUrl/delete_ads2.php';

  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _editing = false;
  String? _errorMessage;
  String? _editingId;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String _placement = 'home';
  int _displaySeconds = 8;
  String _targetType = 'restaurant';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAds2();
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAds {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _ads;

    return _ads.where((ad) {
      final id = ad['id']?.toString().toLowerCase() ?? '';
      final targetType = ad['target_type']?.toString().toLowerCase() ?? '';
      final targetId = ad['target_id']?.toString().toLowerCase() ?? '';
      final createdAt = ad['created_at']?.toString().toLowerCase() ?? '';
      return id.contains(query) ||
          targetType.contains(query) ||
          targetId.contains(query) ||
          createdAt.contains(query);
    }).toList();
  }

  Future<void> _fetchAds2() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse(_ads2Url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final dynamic decoded = json.decode(response.body);
      if (decoded is List) {
        _ads = decoded
            .whereType<Map<String, dynamic>>()
            .map(
              (ad) => {
                'id': ad['id']?.toString() ?? '',
                'image_url': ad['image_url']?.toString() ?? '',
                'link_url': ad['link_url']?.toString() ?? '',
                'target_type': ad['target_type']?.toString() ?? '',
                'target_id': ad['target_id']?.toString() ?? '',
                'placement': ad['placement']?.toString() ?? 'home',
                'display_seconds': ad['display_seconds']?.toString() ?? '8',
                'created_at': ad['created_at']?.toString() ?? '',
              },
            )
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        throw Exception(decoded['message']?.toString() ?? 'Unknown response');
      } else {
        throw Exception('Unexpected response');
      }
    } catch (_) {
      _ads = [];
      _errorMessage = 'تعذر تحميل إعلانات Ads 2 حالياً.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'mp4',
        'webm',
        'mov',
        'm4v',
      ],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _selectedImageBytes = result.files.single.bytes;
      _selectedImageName = result.files.single.name;
    });
  }

  void _resetForm() {
    setState(() {
      _editing = false;
      _editingId = null;
      _targetType = 'restaurant';
      _placement = 'home';
      _displaySeconds = 8;
      _targetIdController.clear();
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  void _startEditing(Map<String, dynamic> ad) {
    setState(() {
      _editing = true;
      _editingId = ad['id']?.toString();
      final rawType = ad['target_type']?.toString().trim().toLowerCase() ?? '';
      _targetType = rawType == 'product' || rawType == 'restaurant'
          ? rawType
          : 'restaurant';
      final rawPlacement =
          ad['placement']?.toString().trim().toLowerCase() ?? '';
      _placement = rawPlacement == 'home_middle' ? 'home_middle' : 'home';
      final parsedSeconds =
          int.tryParse(ad['display_seconds']?.toString() ?? '') ?? 8;
      _displaySeconds =
          const [4, 6, 8, 10, 12].contains(parsedSeconds) ? parsedSeconds : 8;
      final rawId = ad['target_id']?.toString() ?? '';
      _targetIdController.text = rawId;
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
  }

  Future<void> _submitForm() async {
    final isCreate = !_editing;
    if (isCreate && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صورة الإعلان أولاً')),
      );
      return;
    }
    if (_editing && (_editingId == null || _editingId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد الإعلان المراد تعديله')),
      );
      return;
    }

    final targetId = int.tryParse(_targetIdController.text.trim()) ?? 0;
    if (targetId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('أدخل رقم مطعم أو منتج صحيح')),
      );
      return;
    }
    if (_targetType != 'restaurant' && _targetType != 'product') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر توجيه إلى مطعم أو منتج')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(isCreate ? _addUrl : _updateUrl),
      );
      request.fields['target_type'] = _targetType;
      request.fields['target_id'] = targetId.toString();
      request.fields['link_url'] = '$_targetType:$targetId';
      request.fields['placement'] = _placement;
      request.fields['display_seconds'] = _displaySeconds.toString();
      if (!isCreate) {
        request.fields['id'] = _editingId!;
      }
      if (_selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'ad-image.png',
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = json.decode(response.body);

      if (response.statusCode != 200 ||
          decoded is! Map<String, dynamic> ||
          decoded['status'] != 'success') {
        throw Exception(
          decoded is Map<String, dynamic>
              ? decoded['message']?.toString() ?? 'Operation failed'
              : 'Operation failed',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCreate ? 'تمت إضافة الإعلان بنجاح' : 'تم تحديث الإعلان بنجاح',
          ),
        ),
      );
      _resetForm();
      await _fetchAds2();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشلت العملية: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool get _selectedMediaIsVideo {
    final name = _selectedImageName?.toLowerCase() ?? '';
    return name.endsWith('.mp4') ||
        name.endsWith('.webm') ||
        name.endsWith('.mov') ||
        name.endsWith('.m4v');
  }

  bool _urlIsVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.m3u8');
  }

  Future<void> _deleteAd(Map<String, dynamic> ad) async {
    final id = ad['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(Uri.parse(_deleteUrl), body: {'id': id});
      final dynamic decoded = json.decode(response.body);

      if (response.statusCode != 200 ||
          decoded is! Map<String, dynamic> ||
          decoded['status'] != 'success') {
        throw Exception(
          decoded is Map<String, dynamic>
              ? decoded['message']?.toString() ?? 'Delete failed'
              : 'Delete failed',
        );
      }

      if (!mounted) return;
      if (_editingId == id) {
        _resetForm();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإعلان بنجاح')),
      );
      await _fetchAds2();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف الإعلان: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ads = _filteredAds;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text(
          'إدارة Ads 2',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: kSurface,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _fetchAds2,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          children: [
            _buildEditorCard(),
            const SizedBox(height: 18),
            _buildToolbar(),
            const SizedBox(height: 18),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(color: kPrimary),
                ),
              )
            else if (_errorMessage != null)
              _StateCard(
                icon: Icons.campaign_outlined,
                message: _errorMessage!,
                buttonLabel: 'إعادة المحاولة',
                onPressed: _fetchAds2,
              )
            else if (ads.isEmpty)
              _StateCard(
                icon: Icons.image_not_supported_outlined,
                message: _ads.isEmpty
                    ? 'لا توجد إعلانات داخل Ads 2 حالياً.'
                    : 'لا توجد نتائج مطابقة لبحثك.',
                buttonLabel: 'تحديث',
                onPressed: _fetchAds2,
              )
            else
              ...ads.map(_buildAdCard),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kGlow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editing ? 'تعديل إعلان' : 'إضافة إعلان جديد',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _editing
                ? 'يمكنك تعديل الرابط واستبدال الصورة إذا أردت.'
                : 'ارفع صورة الإعلان وأضف رابط التحويل الخاص به.',
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimary.withValues(alpha: 0.12)),
              ),
              child: _selectedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _selectedMediaIsVideo
                          ? Container(
                              color: Colors.black87,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 54,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _selectedImageName ?? 'Video ad',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.perm_media_outlined,
                          size: 42,
                          color: kPrimary,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _editing
                              ? 'اختر صورة جديدة إذا أردت استبدال الحالية'
                              : 'اضغط لاختيار صورة الإعلان',
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_selectedImageName != null) ...[
            const SizedBox(height: 8),
            Text(
              _selectedImageName!,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('ads2-placement-$_placement'),
            initialValue: _placement,
            decoration: const InputDecoration(
              labelText: 'مكان ظهور الإعلان',
            ),
            items: const [
              DropdownMenuItem(
                value: 'home',
                child: Text('السلايدر الرئيسي أعلى الصفحة'),
              ),
              DropdownMenuItem(
                value: 'home_middle',
                child: Text('سلايدر الإعلانات وسط الصفحة'),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _placement = value);
                  },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            key: ValueKey('ads2-display-$_displaySeconds'),
            initialValue: _displaySeconds,
            decoration: const InputDecoration(
              labelText: 'مدة عرض الإعلان',
            ),
            items: const [
              DropdownMenuItem(value: 4, child: Text('4 ثواني')),
              DropdownMenuItem(value: 6, child: Text('6 ثواني')),
              DropdownMenuItem(value: 8, child: Text('8 ثواني')),
              DropdownMenuItem(value: 10, child: Text('10 ثواني')),
              DropdownMenuItem(value: 12, child: Text('12 ثانية')),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _displaySeconds = value);
                  },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('ads2-target-$_targetType'),
            initialValue: _targetType,
            decoration: const InputDecoration(
              labelText: 'توجيه الإعلان',
            ),
            items: const [
              DropdownMenuItem(
                value: 'restaurant',
                child: Text('مطعم'),
              ),
              DropdownMenuItem(
                value: 'product',
                child: Text('منتج'),
              ),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _targetType = value);
                  },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _targetIdController,
            decoration: const InputDecoration(
              labelText: 'رقم الوجهة',
              hintText: 'أدخل رقم المطعم أو المنتج',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForm,
                icon: Icon(_editing ? Icons.save_rounded : Icons.add_rounded),
                label: Text(_editing ? 'حفظ التعديلات' : 'إضافة الإعلان'),
              ),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickImage,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('اختيار صورة'),
              ),
              if (_editing)
                TextButton.icon(
                  onPressed: _isSaving ? null : _resetForm,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('إلغاء التعديل'),
                ),
            ],
          ),
          if (_isSaving) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(color: kPrimary),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'ابحث بالرابط أو رقم الإعلان',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _fetchAds2,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('تحديث'),
        ),
      ],
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final imageUrl = ad['image_url']?.toString() ?? '';
    final targetType = ad['target_type']?.toString().toLowerCase() ?? '';
    final targetId = ad['target_id']?.toString() ?? '';
    final placement = ad['placement']?.toString() ?? 'home';
    final targetLabel = targetType.isEmpty || targetId.isEmpty
        ? 'لا توجد وجهة محددة'
        : targetType == 'restaurant'
            ? 'مطعم #$targetId'
            : 'منتج #$targetId';
    final createdAt = ad['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kGlow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 6,
                child: imageUrl.isEmpty
                    ? Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: kTextSecondary,
                          size: 36,
                        ),
                      )
                    : _urlIsVideo(imageUrl)
                        ? Container(
                            color: Colors.black87,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.play_circle_outline_rounded,
                              color: Colors.white,
                              size: 54,
                            ),
                          )
                        : AppNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ad #${ad['id'] ?? ''}',
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              targetLabel,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Created: $createdAt',
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              placement == 'home_middle'
                  ? 'Placement: home middle ads slider'
                  : 'Placement: home top slider',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startEditing(ad),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('تعديل'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteAd(ad),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  const _StateCard({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
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
              buttonLabel,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }
}
