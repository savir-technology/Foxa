import 'dart:async';

class File {
  File({this.name = ''});

  final String name;
}

class FileReader {
  final StreamController<dynamic> _loadEnd = StreamController<dynamic>();
  final StreamController<dynamic> _error = StreamController<dynamic>();
  dynamic result;

  Stream<dynamic> get onLoadEnd => _loadEnd.stream;
  Stream<dynamic> get onError => _error.stream;

  void readAsArrayBuffer(File file) {}
  void readAsDataUrl(File file) {}
}

class FileUploadInputElement {
  String accept = '';
  bool multiple = false;
  List<File>? files;
  final StreamController<dynamic> _change = StreamController<dynamic>();

  Stream<dynamic> get onChange => _change.stream;
  void click() {}
}

class Window {
  void open(String url, String target) {}
}

final window = Window();

class Blob {
  Blob(List<Object?> parts, [String? type]);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class _Style {
  dynamic width;
  dynamic height;
  dynamic position;
  dynamic right;
  dynamic bottom;
  dynamic border;
  dynamic display;
  dynamic borderRadius;
  dynamic backgroundColor;
  dynamic objectFit;
}

class AnchorElement {
  AnchorElement({String? href});

  dynamic download;
  final style = _Style();
  void click() {}
}

class VideoElement {
  String src = '';
  bool controls = false;
  String preload = '';
  final style = _Style();
  void setAttribute(String name, String value) {}
}

class IFrameElement {
  final style = _Style();
  String srcdoc = '';
  final StreamController<dynamic> _load = StreamController<dynamic>();

  Stream<dynamic> get onLoad => _load.stream;
  void remove() {}
}

class _Body {
  void append(Object element) {}
}

class _Document {
  final _Body? body = _Body();
}

final document = _Document();
