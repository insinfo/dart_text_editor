//C:\MyDartProjects\canvas_text_editor\lib\util\dom_api.dart
// Arquivo: lib/util/dom_api.dart (COMPLETO E CORRIGIDO)
import 'dart:async';

abstract class NodeApi {}

abstract class CanvasElementApi extends NodeApi {
  int get width;
  set width(int value);
  int get height;
  set height(int value);
  CanvasRenderingContext2DApi get context2D;
  RectangleApi getBoundingClientRect();
  Stream<MouseEventApi> get onClick;
  // LINHA ADICIONADA:
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

abstract class DivElementApi extends NodeApi {
  set contentEditable(String value);
  CssStyleDeclarationApi get style;

  int? get tabIndex;
  set tabIndex(int? value);

  void append(NodeApi node);
  void focus();
  Stream<EventApi> get onKeyDown;
  Stream<EventApi> get onKeyUp;
  Stream<MouseEventApi> get onMouseDown;
  Stream<MouseEventApi> get onMouseMove;
  Stream<MouseEventApi> get onMouseUp;
  Stream<MouseEventApi> get onClick;
  Stream<MouseEventApi> get onDoubleClick;
}

abstract class CssStyleDeclarationApi {
  set position(String value);
  set left(String value);
  set top(String value);
  set width(String value);
  set height(String value);
  set opacity(String value);
  set zIndex(String value);

  void setProperty(String name, String value);
}

abstract class RectangleApi {
  double get left;
  double get top;
  double get width;
  double get height;
}

abstract class WindowApi {
  double get devicePixelRatio;
  double get scrollX;
  double get scrollY;
  void requestAnimationFrame(void Function(num highResTime) callback);
  Stream<EventApi> get onResize;
  Stream<EventApi> get onScroll;
}

abstract class DocumentApi {
  BodyElementApi? get body;
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
}

abstract class PointApi {
  int get x;
  int get y;
}