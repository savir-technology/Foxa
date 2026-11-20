import 'package:admin_tks/controler/video_controller.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddVideoPageWeb extends StatelessWidget {
  final VideoController controller = Get.put(VideoController());
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  AddVideoPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 760;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "إدارة الفيديوهات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
            fontFamily: 'Cairo',
            fontSize: 20,
          ),
        ),
      ),
      body: DashboardBackground(
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VideoHero(
                  totalVideos: controller.videos.length,
                  hasFreshUpload: controller.lastUploadedVideoUrl.value != null,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: kGlass,
                    borderRadius: BorderRadius.circular(kBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "رفع فيديو جديد",
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "يمكنك إضافة فيديو جديد ثم تشغيله مباشرة بعد انتهاء الرفع.",
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(context, titleController, "عنوان الفيديو"),
                      const SizedBox(height: 14),
                      _buildTextField(
                        context,
                        descController,
                        "وصف الفيديو",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: controller.targetType.value,
                        decoration: const InputDecoration(
                          labelText: "جهة التوجيه",
                          labelStyle: TextStyle(
                            color: kTextSecondary,
                            fontFamily: 'Cairo',
                          ),
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
                        onChanged: controller.isLoading.value
                            ? null
                            : (value) {
                                if (value == null) return;
                                controller.targetType.value = value;
                                controller.targetIdController.clear();
                              },
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        context,
                        controller.targetIdController,
                        controller.targetType.value == 'product'
                            ? "رقم المنتج"
                            : "رقم المطعم",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.pickVideo,
                            icon: const Icon(Icons.video_library_rounded),
                            label: const Text("اختيار فيديو"),
                          ),
                          ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    final targetId =
                                        int.tryParse(
                                              controller.targetIdController.text
                                                  .trim(),
                                            ) ??
                                            0;
                                    if (targetId <= 0) {
                                      Get.snackbar(
                                        "خطأ",
                                        "أدخل قيمة صحيحة لوجهة الريل",
                                      );
                                      return;
                                    }
                                    controller.uploadVideo(
                                      titleController.text.trim(),
                                      descController.text.trim(),
                                      targetType: controller.targetType.value,
                                      targetId: targetId,
                                    );
                                  },
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: const Text("رفع الفيديو"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kSurface.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kStroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: isPhone ? 170 : 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white,
                                  size: 74,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.selectedVideoName ?? "لم يتم اختيار فيديو بعد",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: controller.selectedVideoName != null
                                    ? Colors.green
                                    : kTextSecondary,
                                fontSize: 13,
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (controller.isLoading.value) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: controller.uploadProgress.value,
                                color: kPrimary,
                                backgroundColor: kSurface.withValues(alpha: 0.35),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${(controller.uploadProgress.value * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.lastUploadedVideoUrl.value != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFFBF7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'آخر فيديو تم رفعه',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.lastUploadedVideoTitle.value ?? 'فيديو جديد',
                          style: const TextStyle(
                            color: kTextSecondary,
                            fontSize: 13,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => controller.openVideoUrl(
                                controller.lastUploadedVideoUrl.value,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('تشغيل الفيديو'),
                            ),
                            OutlinedButton.icon(
                              onPressed: fetchLater(controller),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('تحديث القائمة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  "قائمة الفيديوهات",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                if (controller.videos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: kGlass,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: kStroke),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.video_collection_outlined,
                          color: kPrimary,
                          size: 42,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "لا توجد فيديوهات حالياً",
                          style: TextStyle(
                            color: kTextSecondary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width > 1300
                          ? 3
                          : width > 800
                              ? 2
                              : 1,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      mainAxisExtent: 310,
                    ),
                    itemCount: controller.videos.length,
                    itemBuilder: (context, index) {
                      final video = controller.videos[index];
                      return _VideoCard(
                        video: video,
                        onPlay: () => controller.openVideoUrl(
                          video["video_url"]?.toString(),
                        ),
                        onEdit: () {
                          titleController.text =
                              video["video_title"]?.toString() ?? "";
                          descController.text =
                              video["video_desc"]?.toString() ?? "";
                          final rawTargetType = video["video_target_type"]
                                  ?.toString()
                                  .trim()
                                  .toLowerCase() ??
                              '';
                          final legacyTargetId =
                              video["video_product_id"]?.toString().trim() ?? '';
                          controller.targetType.value =
                              rawTargetType == 'product' ||
                                      rawTargetType == 'item' ||
                                      (rawTargetType.isEmpty &&
                                          legacyTargetId.isNotEmpty)
                                  ? 'product'
                                  : 'restaurant';
                          controller.targetIdController.text =
                              video["video_target_id"]?.toString() ??
                                  (controller.targetType.value == 'product'
                                      ? legacyTargetId
                                      : '');
                          Get.defaultDialog(
                            title: "تعديل الفيديو",
                            titleStyle: const TextStyle(
                              color: kPrimary,
                              fontFamily: 'Cairo',
                            ),
                            content: Obx(
                              () => SizedBox(
                                width: 420,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                  _buildTextField(
                                    context,
                                    titleController,
                                    "العنوان",
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    context,
                                    descController,
                                    "الوصف",
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    value: controller.targetType.value,
                                    decoration: const InputDecoration(
                                      labelText: "جهة التوجيه",
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
                                    onChanged: (value) {
                                      if (value == null) return;
                                      controller.targetType.value = value;
                                      controller.targetIdController.clear();
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                    context,
                                    controller.targetIdController,
                                    controller.targetType.value == 'product'
                                        ? "رقم المنتج"
                                        : "رقم المطعم",
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: controller.pickVideo,
                                    icon: const Icon(Icons.upload_file_rounded),
                                    label: const Text("اختيار فيديو جديد"),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton(
                                    onPressed: () {
                                      final targetId = int.tryParse(
                                            controller.targetIdController.text
                                                .trim(),
                                          ) ??
                                          0;
                                      if (targetId <= 0) {
                                        Get.snackbar(
                                          "خطأ",
                                          "أدخل قيمة صحيحة لوجهة الريل",
                                        );
                                        return;
                                      }
                                      controller.updateVideo(
                                        int.parse(video["video_id"].toString()),
                                        titleController.text.trim(),
                                        descController.text.trim(),
                                        targetType: controller.targetType.value,
                                        targetId: targetId,
                                      );
                                      Get.back();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimary,
                                    ),
                                    child: const Text(
                                      "تحديث",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )           ) ;
                        },
                        onDelete: () {
                          controller.deleteVideo(
                            int.parse(video["video_id"].toString()),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  VoidCallback fetchLater(VideoController controller) {
    return () {
      controller.fetchVideos();
    };
  }

  static Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextPrimary, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kTextSecondary, fontFamily: 'Cairo'),
      ),
    );
  }
}

class _VideoHero extends StatelessWidget {
  final int totalVideos;
  final bool hasFreshUpload;

  const _VideoHero({
    required this.totalVideos,
    required this.hasFreshUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مكتبة الفيديوهات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 6),
              Text(
                'ارفع الفيديو، جرّبه، ثم راقب مكتبتك من واجهة أوضح.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(label: 'إجمالي الفيديوهات', value: '$totalVideos'),
              _HeroChip(
                label: 'آخر حالة',
                value: hasFreshUpload ? 'تم رفع جديد' : 'جاهز',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VideoCard({
    required this.video,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: kPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: IconButton(
                    onPressed: onPlay,
                    iconSize: 74,
                    color: Colors.white,
                    icon: const Icon(Icons.play_circle_fill_rounded),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video["video_title"]?.toString().isNotEmpty == true
                      ? video["video_title"].toString()
                      : "بدون عنوان",
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  video["video_desc"]?.toString() ?? "",
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                _VideoTargetBadge(video: video),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('تشغيل'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('تعديل'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('حذف'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTargetBadge extends StatelessWidget {
  final Map<String, dynamic> video;

  const _VideoTargetBadge({
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    final rawType = video["video_target_type"]?.toString().trim().toLowerCase() ??
        '';
    final legacyId = video["video_product_id"]?.toString().trim() ?? '';
    final targetType = rawType == 'product' ||
            rawType == 'item' ||
            (rawType.isEmpty && legacyId.isNotEmpty)
        ? 'product'
        : (rawType == 'restaurant' ? 'restaurant' : '');
    final rawId = video["video_target_id"]?.toString().trim() ?? '';
    final targetId = rawId.isNotEmpty ? rawId : legacyId;

    if (targetType.isEmpty && targetId.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = targetId.isEmpty
        ? (targetType == 'product' ? 'منتج غير محدد' : 'مطعم غير محدد')
        : (targetType == 'product' ? 'منتج #$targetId' : 'مطعم #$targetId');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Icon(
            targetType == 'product'
                ? Icons.shopping_bag_outlined
                : Icons.storefront_outlined,
            color: kPrimary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
