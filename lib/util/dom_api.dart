// Arquivo: C:\MyDartProjects\canvas_text_editor\lib\util\dom_api.dart
import 'dart:async';

// --- INÍCIO DA CORREÇÃO ---
// Esta é a interface base para todos os elementos do DOM.
// Adicionada a assinatura do método `remove()` que estava faltando.
abstract class ElementApi extends NodeApi {
  CssStyleDeclarationApi get style;
  void remove();
}
// --- FIM DA CORREÇÃO ---

abstract class NodeApi {}

abstract class CanvasElementApi extends ElementApi {
  int get width;
  set width(int value);
  int get height;
  set height(int value);
  CanvasRenderingContext2DApi get context2D;
  RectangleApi getBoundingClientRect();
  Stream<MouseEventApi> get onClick;
  Stream<MouseEventApi> get onDoubleClick;
}

abstract class CanvasRenderingContext2DApi {
  void scale(num x, num y);
  void clearRect(num x, num y, num w, num h);
  void fillText(String text, num x, num y);
  void fillRect(num x, num y, num w, num h);
  void beginPath();
  void rect(num x, num y, num w, num h);
  void clip();
  void save();
  void restore();
  set font(String value);
  set fillStyle(Object value);
  set strokeStyle(Object value);
  set lineWidth(num value);
  void moveTo(num x, num y);
  void lineTo(num x, num y);
  void stroke();
  set textBaseline(String value);
  void translate(num x, num y);
  void strokeRect(num x, num y, num w, num h);
  double measureTextWidth(String text);
}

// --- INÍCIO DA CORREÇÃO ---
// DivElementApi agora herda de ElementApi para ter acesso a `remove()` e `style`.
abstract class DivElementApi extends ElementApi {
// --- FIM DA CORREÇÃO ---
  set contentEditable(String value);
  String get innerText;
  set innerText(String value);
  int? get tabIndex;
  set tabIndex(int? value);
  void append(NodeApi node);
  void focus();
  void select();
  Stream<EventApi> get onKeyDown;
  Stream<EventApi> get onKeyUp;
  Stream<MouseEventApi> get onMouseDown;
  Stream<MouseEventApi> get onMouseMove;
  Stream<MouseEventApi> get onMouseUp;
  Stream<MouseEventApi> get onClick;
  Stream<MouseEventApi> get onDoubleClick;
}

// --- INÍCIO DA CORREÇÃO ---
// Adicionada a interface para TextAreaElement.
abstract class TextAreaElementApi extends ElementApi {
  String get value;
  set value(String value);
  void select();
}
// --- FIM DA CORREÇÃO ---


abstract class CssStyleDeclarationApi {
  set position(String value);
  set left(String value);
  set top(String value);
  set width(String value);
  set height(String value);
  set opacity(String value);
  set zIndex(String value);
  // --- INÍCIO DA CORREÇÃO ---
  // Adicionada a propriedade `pointerEvents` que estava faltando.
  set pointerEvents(String value);
  // --- FIM DA CORREÇÃO ---
  void setProperty(String name, String value);
}

abstract class RectangleApi {
  double get left;
  double get top;
  double get width;
  double get height;
}

abstract class ClipboardApi {
  Future<String?> readText();
  Future<void> writeText(String text);
}

abstract class NavigatorApi {
  ClipboardApi get clipboard;
}

abstract class WindowApi {
  double get devicePixelRatio;
  double get scrollX;
  double get scrollY;
  NavigatorApi get navigator;
  void requestAnimationFrame(void Function(num highResTime) callback);
  Stream<EventApi> get onResize;
  Stream<EventApi> get onScroll;
}

abstract class DocumentApi {
  BodyElementApi? get body;
  bool execCommand(String commandId);
  // --- INÍCIO DA CORREÇÃO ---
  // Adicionado o método `createElement` que estava faltando.
  ElementApi createElement(String tagName);
  // --- FIM DA CORREÇÃO ---
}

abstract class BodyElementApi {
  void append(NodeApi node);
}

abstract class EventApi {
  String get key;
  bool get shiftKey;
  bool get ctrlKey;
  bool get metaKey;
  void preventDefault();
}

abstract class MouseEventApi extends EventApi {
  PointApi get client;
   int get button;
}

abstract class PointApi {
  int get x;
  int get y;
}