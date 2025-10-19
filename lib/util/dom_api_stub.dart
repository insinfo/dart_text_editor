// Lightweight non-web stub implementations for testing on the Dart VM.
import 'dart:async';

import 'dom_api.dart';

class _StubCanvasRenderingContext2D implements CanvasRenderingContext2DApi {
  @override
  double measureTextWidth(String text) => text.length.toDouble() * 7.0;

  @override
  void beginPath() {}
  @override
  void clip() {}
  @override
  void clearRect(num x, num y, num w, num h) {}
  @override
  void fillRect(num x, num y, num w, num h) {}
  @override
  void fillText(String text, num x, num y) {}
  @override
  void lineTo(num x, num y) {}
  @override
  void moveTo(num x, num y) {}
  @override
  void restore() {}
  @override
  void save() {}
  @override
  void scale(num x, num y) {}
  @override
  set font(String value) {}
  @override
  set fillStyle(Object value) {}
  @override
  set strokeStyle(Object value) {}
  @override
  set lineWidth(num value) {}
  @override
  set textBaseline(String value) {}
  @override
  void translate(num x, num y) {}
  @override
  void stroke() {}
  @override
  void strokeRect(num x, num y, num w, num h) {}
  @override
  void rect(num x, num y, num w, num h) {}
}

class _StubCanvasElementApi implements CanvasElementApi {
  @override
  int width = 800;
  @override
  int height = 600;
  final _ctx = _StubCanvasRenderingContext2D();
  @override
  CanvasRenderingContext2DApi get context2D => _ctx;
  @override
  RectangleApi getBoundingClientRect() => _StubRectangleApi();
  @override
  Stream<MouseEventApi> get onClick => const Stream.empty();
}

class _StubRectangleApi implements RectangleApi {
  @override
  double get height => 600.0;
  @override
  double get left => 0.0;
  @override
  double get top => 0.0;
  @override
  double get width => 800.0;
}

class _StubDivElementApi implements DivElementApi {
  final _style = _StubCssStyleDeclarationApi();
  @override
  CssStyleDeclarationApi get style => _style;
  @override
  set contentEditable(String value) {}
  @override
  void append(NodeApi node) {}
  @override
  void focus() {}
  @override
  Stream<EventApi> get onKeyDown => const Stream.empty();
  @override
  Stream<EventApi> get onKeyUp => const Stream.empty();
  @override
  Stream<MouseEventApi> get onMouseDown => const Stream.empty();
  @override
  Stream<MouseEventApi> get onMouseMove => const Stream.empty();
  @override
  Stream<MouseEventApi> get onMouseUp => const Stream.empty();
  @override
  Stream<MouseEventApi> get onClick => const Stream.empty();

  @override
  int? tabIndex;
}

class _StubCssStyleDeclarationApi implements CssStyleDeclarationApi {
  @override
  set height(String value) {}
  @override
  set left(String value) {}
  @override
  set opacity(String value) {}
  @override
  set position(String value) {}
  @override
  set top(String value) {}
  @override
  set width(String value) {}
  @override
  set zIndex(String value) {}
  
  @override
  void setProperty(String name, String value) {
    // TODO: implement setProperty
  }
}

class _StubWindowApi implements WindowApi {
  @override
  double get devicePixelRatio => 1.0;
  @override
  double get scrollX => 0.0;
  @override
  double get scrollY => 0.0;
  @override
  void requestAnimationFrame(void Function(num highResTime) callback) {
    callback(0);
  }

  @override
  Stream<EventApi> get onResize => const Stream.empty();
  @override
  Stream<EventApi> get onScroll => const Stream.empty();
}

class _StubDocumentApi implements DocumentApi {
  final _body = _StubBodyElementApi();
  @override
  BodyElementApi? get body => _body;
}

class _StubBodyElementApi implements BodyElementApi {
  @override
  void append(NodeApi node) {}
}

// Factory functions used by editor when running on non-web platforms
CanvasElementApi createCanvasElement({dynamic canvas}) =>
    _StubCanvasElementApi();
DivElementApi createDivElement() => _StubDivElementApi();
WindowApi createWindow() => _StubWindowApi();
DocumentApi createDocument() => _StubDocumentApi();
