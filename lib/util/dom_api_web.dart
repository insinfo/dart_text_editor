// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:web/web.dart' as web;
import 'package:dart_text_editor/util/dom_api.dart';
import 'dart:js_interop';

// =========================================================================
// == CLASSES DE IMPLEMENTAÇÃO
// =========================================================================

class _DefaultClipboardApi implements ClipboardApi {
  final web.Clipboard _clipboard;
  _DefaultClipboardApi(this._clipboard);

  @override
  Future<String?> readText() async => (await _clipboard.readText().toDart).toDart;
  @override
  Future<void> writeText(String text) async => await _clipboard.writeText(text).toDart;
}

class _UnsupportedClipboardApi implements ClipboardApi {
  @override
  Future<String?> readText() async => null;
  @override
  Future<void> writeText(String text) async {}
}

class _DefaultNavigatorApi implements NavigatorApi {
  @override
  final ClipboardApi clipboard;
  _DefaultNavigatorApi() : clipboard = web.window.navigator.clipboard != null
      ? _DefaultClipboardApi(web.window.navigator.clipboard)
      : _UnsupportedClipboardApi();
}

class _DefaultPointApi implements PointApi {
  @override
  final int x;
  @override
  final int y;
  _DefaultPointApi(this.x, this.y);
}

class _DefaultRectangleApi implements RectangleApi {
  final web.DOMRect _rect;
  _DefaultRectangleApi(this._rect);
  @override
  double get left => _rect.left;
  @override
  double get top => _rect.top;
  @override
  double get width => _rect.width;
  @override
  double get height => _rect.height;
}

class _DefaultEventApi implements EventApi {
  final web.Event _event;
  _DefaultEventApi(this._event);

  @override
  String get key => _event.isA<web.KeyboardEvent>() ? (_event as web.KeyboardEvent).key : '';

  // --- INÍCIO DA CORREÇÃO 1 ---
  // O tipo 'UIEvent' não define 'shiftKey', 'ctrlKey' ou 'metaKey'.
  // É necessário verificar se o evento é um MouseEvent ou KeyboardEvent.
  @override
  bool get shiftKey {
    final event = _event;
    if (event.isA<web.MouseEvent>()) {
      return (event as web.MouseEvent).shiftKey;
    } else if (event.isA<web.KeyboardEvent>()) {
      return (event as web.KeyboardEvent).shiftKey;
    }
    return false;
  }

  @override
  bool get ctrlKey {
    final event = _event;
    if (event.isA<web.MouseEvent>()) {
      return (event as web.MouseEvent).ctrlKey;
    } else if (event.isA<web.KeyboardEvent>()) {
      return (event as web.KeyboardEvent).ctrlKey;
    }
    return false;
  }

  @override
  bool get metaKey {
    final event = _event;
    if (event.isA<web.MouseEvent>()) {
      return (event as web.MouseEvent).metaKey;
    } else if (event.isA<web.KeyboardEvent>()) {
      return (event as web.KeyboardEvent).metaKey;
    }
    return false;
  }
  // --- FIM DA CORREÇÃO 1 ---

  @override
  void preventDefault() => _event.preventDefault();
}

class _DefaultMouseEventApi extends _DefaultEventApi implements MouseEventApi {
  _DefaultMouseEventApi(web.MouseEvent super.event);
  web.MouseEvent get _mouseEvent => _event as web.MouseEvent;
  @override
  PointApi get client => _DefaultPointApi(_mouseEvent.clientX, _mouseEvent.clientY);
  @override
  int get button => _mouseEvent.button;
}

class _DefaultCssStyleDeclarationApi implements CssStyleDeclarationApi {
  final web.CSSStyleDeclaration _style;
  _DefaultCssStyleDeclarationApi(this._style);
  @override
  set position(String value) => _style.position = value;
  @override
  set left(String value) => _style.left = value;
  @override
  set top(String value) => _style.top = value;
  @override
  set width(String value) => _style.width = value;
  @override
  set height(String value) => _style.height = value;
  @override
  set opacity(String value) => _style.opacity = value;
  @override
  set zIndex(String value) => _style.zIndex = value;
  @override
  set pointerEvents(String value) => _style.pointerEvents = value;
  @override
  void setProperty(String name, String value) => _style.setProperty(name, value);
}

abstract class _DefaultElementApi implements ElementApi {
  final web.HTMLElement element;
  _DefaultElementApi(this.element);

  @override
  CssStyleDeclarationApi get style => _DefaultCssStyleDeclarationApi(element.style);

  @override
  void remove() => element.remove();
}

class _DefaultCanvasRenderingContext2DApi implements CanvasRenderingContext2DApi {
  final web.CanvasRenderingContext2D _ctx;
  _DefaultCanvasRenderingContext2DApi(this._ctx);
  @override
  void scale(num x, num y) => _ctx.scale(x.toDouble(), y.toDouble());
  @override
  void clearRect(num x, num y, num w, num h) => _ctx.clearRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  @override
  void fillText(String text, num x, num y) => _ctx.fillText(text, x.toDouble(), y.toDouble());
  @override
  void fillRect(num x, num y, num w, num h) => _ctx.fillRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  @override
  void beginPath() => _ctx.beginPath();
  @override
  void rect(num x, num y, num w, num h) => _ctx.rect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  @override
  void clip() => _ctx.clip();
  @override
  void save() => _ctx.save();
  @override
  void restore() => _ctx.restore();
  @override
  set font(String value) => _ctx.font = value;
  @override
  set fillStyle(Object value) => _ctx.fillStyle = (value as String).toJS;
  @override
  set strokeStyle(Object value) => _ctx.strokeStyle = (value as String).toJS;
  @override
  set lineWidth(num value) => _ctx.lineWidth = value.toDouble();
  @override
  void moveTo(num x, num y) => _ctx.moveTo(x.toDouble(), y.toDouble());
  @override
  void lineTo(num x, num y) => _ctx.lineTo(x.toDouble(), y.toDouble());
  @override
  void stroke() => _ctx.stroke();
  @override
  set textBaseline(String value) => _ctx.textBaseline = value;
  @override
  void translate(num x, num y) => _ctx.translate(x.toDouble(), y.toDouble());
  @override
  void strokeRect(num x, num y, num w, num h) => _ctx.strokeRect(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  @override
  double measureTextWidth(String text) => _ctx.measureText(text).width;
}

class _DefaultCanvasElementApi extends _DefaultElementApi implements CanvasElementApi {
  _DefaultCanvasElementApi(web.HTMLCanvasElement super.element);
  web.HTMLCanvasElement get canvasElement => element as web.HTMLCanvasElement;

  @override
  int get width => canvasElement.width;
  @override
  set width(int value) => canvasElement.width = value;
  @override
  int get height => canvasElement.height;
  @override
  set height(int value) => canvasElement.height = value;
  
  // --- INÍCIO DA CORREÇÃO 2 ---
  // Corrigido o nome do construtor para corresponder à definição da classe privada.
  @override
  CanvasRenderingContext2DApi get context2D => _DefaultCanvasRenderingContext2DApi(canvasElement.getContext('2d') as web.CanvasRenderingContext2D);
  // --- FIM DA CORREÇÃO 2 ---

  @override
  RectangleApi getBoundingClientRect() => _DefaultRectangleApi(canvasElement.getBoundingClientRect());
  @override
  Stream<MouseEventApi> get onClick => _createEventStream(canvasElement, 'click', (web.MouseEvent e) => _DefaultMouseEventApi(e));
  @override
  Stream<MouseEventApi> get onDoubleClick => _createEventStream(canvasElement, 'dblclick', (web.MouseEvent e) => _DefaultMouseEventApi(e));
}

class _DefaultDivElementApi extends _DefaultElementApi implements DivElementApi {
  _DefaultDivElementApi(web.HTMLDivElement super.element);
  web.HTMLDivElement get divElement => element as web.HTMLDivElement;

  @override
  set contentEditable(String value) => divElement.contentEditable = value;
  @override
  String get innerText => divElement.innerText;
  @override
  set innerText(String value) => divElement.innerText = value;
  @override
  void select() {
    final selection = web.window.getSelection();
    if (selection != null) {
      final range = web.document.createRange();
      range.selectNodeContents(divElement);
      selection.removeAllRanges();
      selection.addRange(range);
    }
  }
  @override
  void append(NodeApi node) {
    if (node is _DefaultElementApi) {
      divElement.appendChild(node.element);
    }
  }
  @override
  int get tabIndex => divElement.tabIndex;
  @override
  set tabIndex(int? v) => divElement.tabIndex = v ?? -1;
  @override
  void focus() => divElement.focus();
  @override
  Stream<EventApi> get onKeyDown => _createEventStream(divElement, 'keydown', (web.KeyboardEvent e) => _DefaultEventApi(e));
  @override
  Stream<EventApi> get onKeyUp => _createEventStream(divElement, 'keyup', (web.KeyboardEvent e) => _DefaultEventApi(e));
  @override
  Stream<MouseEventApi> get onMouseDown => _createEventStream(divElement, 'mousedown', (web.MouseEvent e) => _DefaultMouseEventApi(e));
  @override
  Stream<MouseEventApi> get onMouseMove => _createEventStream(divElement, 'mousemove', (web.MouseEvent e) => _DefaultMouseEventApi(e));
  @override
  Stream<MouseEventApi> get onMouseUp => _createEventStream(divElement, 'mouseup', (web.MouseEvent e) => _DefaultMouseEventApi(e));
  @override
  Stream<MouseEventApi> get onClick => _createEventStream(divElement, 'click', (web.MouseEvent e) => _DefaultMouseEventApi(e));
  @override
  Stream<MouseEventApi> get onDoubleClick => _createEventStream(divElement, 'dblclick', (web.MouseEvent e) => _DefaultMouseEventApi(e));
}

class _DefaultTextAreaElementApi extends _DefaultElementApi implements TextAreaElementApi {
  _DefaultTextAreaElementApi(web.HTMLTextAreaElement super.element);
  web.HTMLTextAreaElement get textAreaElement => element as web.HTMLTextAreaElement;

  @override
  String get value => textAreaElement.value;
  @override
  set value(String value) => textAreaElement.value = value;
  @override
  void select() => textAreaElement.select();
}

class _DefaultBodyElementApi implements BodyElementApi {
  @override
  void append(NodeApi node) {
    if (node is _DefaultElementApi) {
      web.document.body!.appendChild(node.element);
    }
  }
}

class _DefaultDocumentApi implements DocumentApi {
  @override
  BodyElementApi? get body => web.document.body != null ? _DefaultBodyElementApi() : null;
  @override
  bool execCommand(String commandId) => web.document.execCommand(commandId);

  @override
  ElementApi createElement(String tagName) {
    final element = web.document.createElement(tagName);
    if (element.isA<web.HTMLCanvasElement>()) {
      return _DefaultCanvasElementApi(element as web.HTMLCanvasElement);
    }
    if (element.isA<web.HTMLDivElement>()) {
      return _DefaultDivElementApi(element as web.HTMLDivElement);
    }
    if (element.isA<web.HTMLTextAreaElement>()) {
      return _DefaultTextAreaElementApi(element as web.HTMLTextAreaElement);
    }
    throw UnsupportedError('Element type "$tagName" is not supported by the DOM API abstraction.');
  }
}

class _DefaultWindowApi implements WindowApi {
  @override
  double get devicePixelRatio => web.window.devicePixelRatio;
  @override
  double get scrollX => web.window.scrollX;
  @override
  double get scrollY => web.window.scrollY;
  @override
  final NavigatorApi navigator = _DefaultNavigatorApi();
  @override
  void requestAnimationFrame(void Function(num highResTime) callback) => web.window.requestAnimationFrame(callback.toJS);
  @override
  Stream<EventApi> get onResize => _createEventStream(web.window, 'resize', (web.Event e) => _DefaultEventApi(e));
  @override
  Stream<EventApi> get onScroll => _createEventStream(web.window, 'scroll', (web.Event e) => _DefaultEventApi(e));
}

// =========================================================================
// == FUNÇÕES DE FÁBRICA PÚBLICAS E HELPERS GLOBAIS
// =========================================================================

Stream<E> _createEventStream<T extends web.Event, E>(web.EventTarget target, String eventType, E Function(T) converter) {
  final controller = StreamController<E>.broadcast();
  controller.onListen = () {
    target.addEventListener(eventType, (web.Event event) {
      controller.add(converter(event as T));
    }.toJS);
  };
  return controller.stream;
}

WindowApi createWindow() => _DefaultWindowApi();
DocumentApi createDocument() => _DefaultDocumentApi();
DivElementApi createDivElement() => _DefaultDivElementApi(web.document.createElement('div') as web.HTMLDivElement);
CanvasElementApi createCanvasElement({web.HTMLCanvasElement? canvas}) =>
    _DefaultCanvasElementApi(canvas ?? web.document.createElement('canvas') as web.HTMLCanvasElement);