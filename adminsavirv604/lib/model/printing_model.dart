import 'dart:convert';

class PrintingDashboardSnapshot {
  const PrintingDashboardSnapshot({
    required this.summary,
    required this.printers,
    required this.templates,
    required this.settings,
  });

  final PrintSummary summary;
  final List<VendorPrinter> printers;
  final List<InvoiceTemplate> templates;
  final PrintSettings settings;

  factory PrintingDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final printersRaw = json['printers'];
    final templatesRaw = json['templates'];

    return PrintingDashboardSnapshot(
      summary: PrintSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      printers: printersRaw is List
          ? printersRaw
              .whereType<Map>()
              .map((entry) =>
                  VendorPrinter.fromJson(entry.cast<String, dynamic>()))
              .toList()
          : const [],
      templates: templatesRaw is List
          ? templatesRaw
              .whereType<Map>()
              .map((entry) =>
                  InvoiceTemplate.fromJson(entry.cast<String, dynamic>()))
              .toList()
          : const [],
      settings: PrintSettings.fromJson(
        (json['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}

class PrintSummary {
  const PrintSummary({
    required this.printedToday,
    required this.templateTypes,
    required this.disconnectedPrinters,
    required this.connectedPrinters,
    required this.totalPrinters,
  });

  final int printedToday;
  final int templateTypes;
  final int disconnectedPrinters;
  final int connectedPrinters;
  final int totalPrinters;

  factory PrintSummary.fromJson(Map<String, dynamic> json) {
    return PrintSummary(
      printedToday: _toInt(json['printed_today']),
      templateTypes: _toInt(json['template_types']),
      disconnectedPrinters: _toInt(json['disconnected_printers']),
      connectedPrinters: _toInt(json['connected_printers']),
      totalPrinters: _toInt(json['total_printers']),
    );
  }
}

class VendorPrinter {
  const VendorPrinter({
    required this.id,
    required this.name,
    required this.model,
    required this.type,
    required this.location,
    required this.sections,
    required this.ip,
    required this.port,
    required this.connected,
    required this.active,
    required this.lastPrintAt,
  });

  final int id;
  final String name;
  final String model;
  final String type;
  final String location;
  final List<String> sections;
  final String ip;
  final int? port;
  final bool connected;
  final bool active;
  final DateTime? lastPrintAt;

  factory VendorPrinter.fromJson(Map<String, dynamic> json) {
    return VendorPrinter(
      id: _toInt(json['printer_id']),
      name: json['printer_name']?.toString().trim() ?? '',
      model: json['printer_model']?.toString().trim() ?? '',
      type: json['printer_type']?.toString().trim() ?? 'invoice',
      location: json['printer_location']?.toString().trim() ?? '',
      sections: _parseStringList(json['printer_sections_json']),
      ip: json['printer_ip']?.toString().trim() ?? '',
      port: _nullableInt(json['printer_port']),
      connected: _toBool(json['is_connected']),
      active: _toBool(json['is_active'], defaultValue: true),
      lastPrintAt: _toDateTime(json['last_print_at']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'printer_id': id,
      'printer_name': name,
      'printer_model': model,
      'printer_type': type,
      'printer_location': location,
      'printer_sections': sections,
      'printer_ip': ip,
      'printer_port': port,
      'is_connected': connected ? 1 : 0,
    };
  }

  VendorPrinter copyWith({
    int? id,
    String? name,
    String? model,
    String? type,
    String? location,
    List<String>? sections,
    String? ip,
    int? port,
    bool? connected,
    bool? active,
    DateTime? lastPrintAt,
  }) {
    return VendorPrinter(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      type: type ?? this.type,
      location: location ?? this.location,
      sections: sections ?? this.sections,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      connected: connected ?? this.connected,
      active: active ?? this.active,
      lastPrintAt: lastPrintAt ?? this.lastPrintAt,
    );
  }
}

class InvoiceTemplate {
  const InvoiceTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.paperWidthMm,
    required this.paperHeightMm,
    required this.usage,
    required this.active,
  });

  final int id;
  final String name;
  final String type;
  final int paperWidthMm;
  final int? paperHeightMm;
  final String usage;
  final bool active;

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      id: _toInt(json['template_id']),
      name: json['template_name']?.toString().trim() ?? '',
      type: json['template_type']?.toString().trim() ?? 'invoice',
      paperWidthMm: _toInt(json['paper_width_mm'], defaultValue: 80),
      paperHeightMm: _nullableInt(json['paper_height_mm']),
      usage: json['template_usage']?.toString().trim() ?? '',
      active: _toBool(json['is_active'], defaultValue: true),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'template_id': id,
      'template_name': name,
      'template_type': type,
      'paper_width_mm': paperWidthMm,
      'paper_height_mm': paperHeightMm,
      'template_usage': usage,
    };
  }

  InvoiceTemplate copyWith({
    int? id,
    String? name,
    String? type,
    int? paperWidthMm,
    int? paperHeightMm,
    String? usage,
    bool? active,
  }) {
    return InvoiceTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      paperHeightMm: paperHeightMm ?? this.paperHeightMm,
      usage: usage ?? this.usage,
      active: active ?? this.active,
    );
  }
}

class PrintSettings {
  const PrintSettings({
    required this.direction,
    required this.fontSize,
    required this.invoiceCopies,
    required this.printLogo,
  });

  final String direction;
  final String fontSize;
  final int invoiceCopies;
  final bool printLogo;

  factory PrintSettings.fromJson(Map<String, dynamic> json) {
    return PrintSettings(
      direction: json['default_direction']?.toString().trim().isNotEmpty == true
          ? json['default_direction'].toString().trim()
          : 'rtl_ar',
      fontSize: json['default_font_size']?.toString().trim().isNotEmpty == true
          ? json['default_font_size'].toString().trim()
          : 'medium',
      invoiceCopies:
          _toInt(json['invoice_copies'], defaultValue: 1).clamp(1, 5).toInt(),
      printLogo: _toBool(json['print_logo'], defaultValue: true),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'default_direction': direction,
      'default_font_size': fontSize,
      'invoice_copies': invoiceCopies,
      'print_logo': printLogo ? 1 : 0,
    };
  }

  PrintSettings copyWith({
    String? direction,
    String? fontSize,
    int? invoiceCopies,
    bool? printLogo,
  }) {
    return PrintSettings(
      direction: direction ?? this.direction,
      fontSize: fontSize ?? this.fontSize,
      invoiceCopies: invoiceCopies ?? this.invoiceCopies,
      printLogo: printLogo ?? this.printLogo,
    );
  }
}

int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? defaultValue;
}

int? _nullableInt(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  return int.tryParse(raw);
}

bool _toBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) {
    return defaultValue;
  }
  if (value is bool) {
    return value;
  }
  final raw = value.toString().trim().toLowerCase();
  if (raw.isEmpty) {
    return defaultValue;
  }
  return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
}

DateTime? _toDateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty || raw.toLowerCase() == 'null') {
    return null;
  }
  return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return const [];
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return _parseStringList(decoded);
    }
  } catch (_) {
    // Fall back to text splitting below.
  }

  return raw
      .split(RegExp(r'\r\n|\r|\n|,'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
