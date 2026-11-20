class _PlatformViewRegistry {
  void registerViewFactory(
    String viewType,
    Object Function(int viewId) factory,
  ) {}
}

final platformViewRegistry = _PlatformViewRegistry();
