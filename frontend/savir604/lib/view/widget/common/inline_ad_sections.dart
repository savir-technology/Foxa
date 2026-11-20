import 'package:flutter/material.dart';
import 'package:tks/data/datasource/model/admodel.dart';
import 'package:tks/data/datasource/remote/ads/ads_data.dart';
import 'package:tks/view/widget/common/inline_ad_banner.dart';

typedef InlineAdItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

class InlineAdProductFeed<T> extends StatefulWidget {
  final List<T> items;
  final InlineAdItemBuilder<T> itemBuilder;
  final String placement;
  final int itemsPerRow;
  final double itemSpacing;
  final double rowSpacing;
  final double adHeight;
  final double childAspectRatio;

  const InlineAdProductFeed({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.placement,
    this.itemsPerRow = 2,
    this.itemSpacing = 14,
    this.rowSpacing = 16,
    this.adHeight = 124,
    this.childAspectRatio = 0.56,
  });

  @override
  State<InlineAdProductFeed<T>> createState() => _InlineAdProductFeedState<T>();
}

class _InlineAdProductFeedState<T> extends State<InlineAdProductFeed<T>> {
  final AdsData _adsData = AdsData();
  List<AdModel> _ads = const <AdModel>[];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void didUpdateWidget(covariant InlineAdProductFeed<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _loadAds();
    }
  }

  Future<void> _loadAds() async {
    final ads = await _adsData.fetchAds(placement: widget.placement);
    if (!mounted) return;
    setState(() => _ads = ads);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    final rowCount = (widget.items.length / widget.itemsPerRow).ceil();

    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final start = rowIndex * widget.itemsPerRow;
      final end = start + widget.itemsPerRow > widget.items.length
          ? widget.items.length
          : start + widget.itemsPerRow;
      final rowChildren = <Widget>[];

      for (var index = start; index < end; index++) {
        rowChildren.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: widget.childAspectRatio,
              child: widget.itemBuilder(context, widget.items[index], index),
            ),
          ),
        );
        if (index < end - 1) {
          rowChildren.add(SizedBox(width: widget.itemSpacing));
        }
      }

      final missingSlots = widget.itemsPerRow - (end - start);
      for (var i = 0; i < missingSlots; i++) {
        if (rowChildren.isNotEmpty) {
          rowChildren.add(SizedBox(width: widget.itemSpacing));
        }
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }

      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowChildren,
        ),
      );

      final isLastRow = rowIndex == rowCount - 1;
      if (isLastRow) continue;

      children.add(SizedBox(height: widget.rowSpacing));
      if (_ads.isNotEmpty) {
        children.add(
          InlineAdBanner(
            placement: widget.placement,
            ads: _ads,
            height: widget.adHeight,
            enableAutoRotate: false,
            showIndicators: false,
            initialIndex: rowIndex % _ads.length,
          ),
        );
        children.add(SizedBox(height: widget.rowSpacing));
      }
    }

    return Column(children: children);
  }
}

class InlineAdListFeed<T> extends StatefulWidget {
  final List<T> items;
  final InlineAdItemBuilder<T> itemBuilder;
  final String placement;
  final int itemsPerAd;
  final double itemSpacing;
  final double adHeight;

  const InlineAdListFeed({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.placement,
    this.itemsPerAd = 2,
    this.itemSpacing = 12,
    this.adHeight = 118,
  });

  @override
  State<InlineAdListFeed<T>> createState() => _InlineAdListFeedState<T>();
}

class _InlineAdListFeedState<T> extends State<InlineAdListFeed<T>> {
  final AdsData _adsData = AdsData();
  List<AdModel> _ads = const <AdModel>[];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void didUpdateWidget(covariant InlineAdListFeed<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _loadAds();
    }
  }

  Future<void> _loadAds() async {
    final ads = await _adsData.fetchAds(placement: widget.placement);
    if (!mounted) return;
    setState(() => _ads = ads);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (var index = 0; index < widget.items.length; index++) {
      children.add(widget.itemBuilder(context, widget.items[index], index));

      final isLastItem = index == widget.items.length - 1;
      if (isLastItem) continue;

      children.add(SizedBox(height: widget.itemSpacing));

      final showAd = _ads.isNotEmpty && (index + 1) % widget.itemsPerAd == 0;
      if (showAd) {
        children.add(
          InlineAdBanner(
            placement: widget.placement,
            ads: _ads,
            height: widget.adHeight,
            enableAutoRotate: false,
            showIndicators: false,
            initialIndex: ((index + 1) ~/ widget.itemsPerAd - 1) % _ads.length,
          ),
        );
        children.add(SizedBox(height: widget.itemSpacing));
      }
    }

    return Column(children: children);
  }
}
