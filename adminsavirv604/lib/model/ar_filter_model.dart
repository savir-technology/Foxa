class ArFilterModel {
  final String? filterId;
  final String? itemId;
  final String? overlayImagePath;
  final String? overlayImageUrl;
  final String? scaleFactor;
  final String? offsetX;
  final String? offsetY;
  final String? rotationAdjust;
  final String? bridgeYAdjust;

  ArFilterModel({
    this.filterId,
    this.itemId,
    this.overlayImagePath,
    this.overlayImageUrl,
    this.scaleFactor,
    this.offsetX,
    this.offsetY,
    this.rotationAdjust,
    this.bridgeYAdjust,
  });

  factory ArFilterModel.fromJson(Map<String, dynamic> json) {
    return ArFilterModel(
      filterId: json['filter_id']?.toString(),
      itemId: json['item_id']?.toString(),
      overlayImagePath: json['overlay_image_path']?.toString(),
      overlayImageUrl: json['overlay_image_url']?.toString(),
      scaleFactor: json['scale_factor']?.toString(),
      offsetX: json['offset_x']?.toString(),
      offsetY: json['offset_y']?.toString(),
      rotationAdjust: json['rotation_adjust']?.toString(),
      bridgeYAdjust: json['bridge_y_adjust']?.toString(),
    );
  }
}
