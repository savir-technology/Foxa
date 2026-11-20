import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/model/ar_filter_model.dart';
import 'package:admin_tks/model/model_items.dart';
import 'package:admin_tks/remote/ar_filter_data.dart';
import 'package:admin_tks/remote/items_data.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ArFramesPage extends StatefulWidget {
  const ArFramesPage({super.key});

  @override
  State<ArFramesPage> createState() => _ArFramesPageState();
}

class _ArFramesPageState extends State<ArFramesPage> {
  static const int _maxArFrameBytes = 700 * 1024;
  static const double _defaultArScaleFactor = 0.10;

  final ItemsData itemsData = ItemsData();
  final ArFilterData arFilterData = ArFilterData();
  final TextEditingController searchController = TextEditingController();

  List<ItemsModel> items = [];
  final Map<String, ArFilterModel?> arByItem = {};
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    setState(() => loading = true);

    final result = await itemsData.getItems() ?? [];
    final Map<String, ArFilterModel?> loadedFilters = {};

    for (final item in result) {
      final itemId = item.itemsId;
      if (itemId == null || itemId.isEmpty) {
        continue;
      }
      loadedFilters[itemId] = await arFilterData.getItemArFilter(itemId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      items = result;
      arByItem
        ..clear()
        ..addAll(loadedFilters);
      loading = false;
    });
  }

  Future<void> _uploadArForItem(ItemsModel item) async {
    final itemId = item.itemsId;
    if (itemId == null || itemId.isEmpty) {
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (picked == null || picked.files.single.bytes == null) {
      return;
    }

    final Uint8List imageBytes = picked.files.single.bytes!;
    if (imageBytes.lengthInBytes > _maxArFrameBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AR frame image must be 700 KB or smaller.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final updated = await arFilterData.upsertItemArFilter(
      itemId: itemId,
      overlayImageBase64: base64Encode(imageBytes),
      scaleFactor: _defaultArScaleFactor,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    if (updated != null) {
      setState(() {
        arByItem[itemId] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AR frame uploaded for ${item.itemsNameAr ?? item.itemsNameEn ?? 'this product'}.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to upload the AR frame image.')),
    );
  }

  List<ItemsModel> get _filteredItems {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }

    return items.where((item) {
      final arName = item.itemsNameAr?.toLowerCase() ?? '';
      final enName = item.itemsNameEn?.toLowerCase() ?? '';
      final id = item.itemsId?.toLowerCase() ?? '';
      return arName.contains(query) || enName.contains(query) || id.contains(query);
    }).toList();
  }

  Widget _productImage(ItemsModel item) {
    if (item.itemsImage != null && item.itemsImage!.isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 180,
            maxHeight: 90,
          ),
          child: AppNetworkImage(
            imageUrl:
                'https://savir-technology.online/roaqv2/uploud/items/${item.itemsImage}',
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const Center(child: Icon(Icons.image_not_supported_outlined, size: 36));
  }

  Widget _arImage(ArFilterModel? filter) {
    final imageUrl = filter?.overlayImageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 220,
            maxHeight: 100,
          ),
          child: AppNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'No AR frame uploaded yet',
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'AR Frames',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: fetch,
                        icon: Icon(
                          Icons.refresh,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search by product name or ID',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Upload transparent PNG files up to 700 KB for stable AR performance.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            items.isEmpty
                                ? 'No products were found to manage AR frames.'
                                : 'No products match your current search.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final filter = arByItem[item.itemsId ?? ''];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemsNameAr ?? item.itemsNameEn ?? 'Unnamed product',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.itemsId != null && item.itemsId!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Product ID: ${item.itemsId}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Product image'),
                                            const SizedBox(height: 8),
                                            SizedBox(height: 140, child: _productImage(item)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('AR frame image'),
                                            const SizedBox(height: 8),
                                            SizedBox(height: 140, child: _arImage(filter)),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Default scale on upload: ${_defaultArScaleFactor.toStringAsFixed(2)}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    filter?.overlayImagePath?.isNotEmpty == true
                                        ? 'Current file: ${filter!.overlayImagePath!}'
                                        : 'No AR frame has been uploaded for this product yet.',
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _uploadArForItem(item),
                                      icon: const Icon(Icons.upload_file),
                                      label: Text(
                                        filter == null ? 'Upload AR frame' : 'Update AR frame',
                                      ),
                                    ),
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

