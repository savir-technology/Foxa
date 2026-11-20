class NavigationLaneGuidance {
  const NavigationLaneGuidance({
    required this.indications,
    required this.isValid,
    required this.isActive,
  });

  final List<String> indications;
  final bool isValid;
  final bool isActive;
}
