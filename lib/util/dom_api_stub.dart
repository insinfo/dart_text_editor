// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\util\dom_api_stub.dart
import 'dart:async';
import 'package:dart_text_editor/util/dom_api.dart';

class _StubClipboardApi implements ClipboardApi {
  String _clipboardContent = '';
  @override
  Future<String?> readText() async => _clipboardContent;
  @override
  Future<void> writeText(String text) async => _clipboardContent = text;
}

class _StubNavigatorApi implements NavigatorApi {
  @override
  final ClipboardApi clipboard = _StubClipboardApi();
}

class _StubCanvasRenderingContext2D implements CanvasRenderingContext2DApi {
  @override
  double measureTextWidth(String text) => text.length.toDouble() * 8.0;
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

// CORREÇÃO: Implementação dos novos membros da interface ElementApi.
abstract class _StubElementApi implements ElementApi {
  @override
  final CssStyleDeclarationApi style = _StubCssStyleDeclarationApi();
  @override
  void remove() {}
}

class _StubCanvasElementApi extends _StubElementApi implements CanvasElementApi {
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
  @override
  Stream<MouseEventApi> get onDoubleClick => const Stream.empty();
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

class _StubDivElementApi extends _StubElementApi implements DivElementApi {
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
  Stream<MouseEventApi> get onDoubleClick => const Stream.empty();
  @override
  int? tabIndex;
  @override
  String innerText = '';
  @override
  void select() {}
}

// CORREÇÃO: Implementação do novo membro `value`.
class _StubTextAreaElementApi extends _StubElementApi implements TextAreaElementApi {
  @override
  String value = '';
  @override
  void select() {}
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
  void setProperty(String name, String value) {}
  // CORREÇÃO: Implementação do novo membro `pointerEvents`.
  @override
  set pointerEvents(String value) {}
}

class _StubWindowApi implements WindowApi {
  @override
  double get devicePixelRatio => 1.0;
  @override
  double get scrollX => 0.0;
  @override
  double get scrollY => 0.0;
  @override
  final NavigatorApi navigator = _StubNavigatorApi();
  @override
  void requestAnimationFrame(void Function(num highResTime) callback) => callback(0);
  @override
  Stream<EventApi> get onResize => const Stream.empty();
  @override
  Stream<EventApi> get onScroll => const Stream.empty();
}

class _StubDocumentApi implements DocumentApi {
  final _body = _StubBodyElementApi();
  @override
  BodyElementApi? get body => _body; 
  @override
  bool execCommand(String commandId) => true;
  // CORREÇÃO: Implementação do novo método `createElement`.
  @override
  ElementApi createElement(String tagName) {
    if (tagName == 'textarea') {
      return _StubTextAreaElementApi();
    }
    return _StubDivElementApi(); // Retorna um Div como fallback.
  }
}

class _StubBodyElementApi implements BodyElementApi {
  @override
  void append(NodeApi node) {}
}

CanvasElementApi createCanvasElement({dynamic canvas}) => _StubCanvasElementApi();
DivElementApi createDivElement() => _StubDivElementApi();
WindowApi createWindow() => _StubWindowApi();
DocumentApi createDocument() => _StubDocumentApi();