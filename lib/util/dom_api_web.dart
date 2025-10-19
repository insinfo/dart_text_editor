// Arquivo: lib/util/dom_api_web.dart (COMPLETO E CORRIGIDO)
// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:html' as html;
import 'package:dart_text_editor/util/dom_api.dart';

// --------------------------------------
// Implementações “default” (navegador)
// --------------------------------------

class _DefaultWindowApi implements WindowApi {
  @override
  double get devicePixelRatio => html.window.devicePixelRatio.toDouble();
  @override
  double get scrollX => html.window.scrollX.toDouble();
  @override
  double get scrollY => html.window.scrollY.toDouble();
  @override
  void requestAnimationFrame(void Function(num highResTime) callback) {
    html.window.requestAnimationFrame(callback);
  }

  @override
  Stream<EventApi> get onResize =>
      html.window.onResize.map((event) => _DefaultEventApi(event));
  @override
  Stream<EventApi> get onScroll =>
      html.window.onScroll.map((event) => _DefaultEventApi(event));
}

class _DefaultDocumentApi implements DocumentApi {
  @override
  BodyElementApi? get body => _DefaultBodyElementApi();
}

class _DefaultBodyElementApi implements BodyElementApi {
  @override
  void append(NodeApi node) {
    if (node is _DefaultDivElementApi) {
      html.document.body!.append(node.divElement);
    } else if (node is _DefaultCanvasElementApi) {
      html.document.body!.append(node.canvasElement);
    }
  }
}

class _DefaultDivElementApi implements DivElementApi {
  final html.DivElement divElement = html.DivElement();

  @override
  set contentEditable(String value) => divElement.contentEditable = value;

  @override
  CssStyleDeclarationApi get style =>
      _DefaultCssStyleDeclarationApi(divElement.style);

  @override
  void append(NodeApi node) {
    if (node is _DefaultDivElementApi) {
      divElement.append(node.divElement);
    } else if (node is _DefaultCanvasElementApi) {
      divElement.append(node.canvasElement);
    }
  }

  @override
  int? get tabIndex => divElement.tabIndex;
  @override
  set tabIndex(int? v) => divElement.tabIndex = v;

  @override
  void focus() => divElement.focus();

  // Teclado → EventApi
  @override
  Stream<EventApi> get onKeyDown =>
      divElement.onKeyDown.map((event) => _DefaultEventApi(event));
  @override
  Stream<EventApi> get onKeyUp =>
      divElement.onKeyUp.map((event) => _DefaultEventApi(event));

  // Mouse → MouseEventApi
  // CORREÇÃO: Adiciona o tipo explícito (html.MouseEvent event) ao lambda.
  @override
  Stream<MouseEventApi> get onMouseDown => divElement.onMouseDown
      .map((html.MouseEvent event) => _DefaultMouseEventApi(event));
  @override
  Stream<MouseEventApi> get onMouseMove => divElement.onMouseMove
      .map((html.MouseEvent event) => _DefaultMouseEventApi(event));
  @override
  Stream<MouseEventApi> get onMouseUp => divElement.onMouseUp
      .map((html.MouseEvent event) => _DefaultMouseEventApi(event));
  @override
  Stream<MouseEventApi> get onClick => divElement.onClick
      .map((html.MouseEvent event) => _DefaultMouseEventApi(event));

  // CORREÇÃO: O evento de onDoubleClick em dart:html é um Stream<Event>,
  // então fazemos o cast para MouseEvent, que é o que ele será na prática.
  @override
  Stream<MouseEventApi> get onDoubleClick => divElement.onDoubleClick
      .map((event) => _DefaultMouseEventApi(event as html.MouseEvent));
}

class _DefaultCssStyleDeclarationApi implements CssStyleDeclarationApi {
  final html.CssStyleDeclaration _style;
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
  void setProperty(String name, String value) =>
      _style.setProperty(name, value);
}

class _DefaultCanvasElementApi implements CanvasElementApi {
  final html.CanvasElement canvasElement;

  _DefaultCanvasElementApi({html.CanvasElement? canvas})
      : canvasElement = canvas ?? html.CanvasElement();

  @override
  int get width => canvasElement.width ?? 0;
  @override
  set width(int value) => canvasElement.width = value;

  @override
  int get height => canvasElement.height ?? 0;
  @override
  set height(int value) => canvasElement.height = value;

  @override
  CanvasRenderingContext2DApi get context2D =>
      _DefaultCanvasRenderingContext2DApi(
        canvasElement.context2D,
      );

  @override
  RectangleApi getBoundingClientRect() =>
      _DefaultRectangleApi(canvasElement.getBoundingClientRect());

  @override
  Stream<MouseEventApi> get onClick => canvasElement.onClick
      .map((html.MouseEvent event) => _DefaultMouseEventApi(event));

  @override
  Stream<MouseEventApi> get onDoubleClick => canvasElement.onDoubleClick
      .map((event) => _DefaultMouseEventApi(event as html.MouseEvent));
}

class _DefaultCanvasRenderingContext2DApi
    implements CanvasRenderingContext2DApi {
  final html.CanvasRenderingContext2D _ctx;
  _DefaultCanvasRenderingContext2DApi(this._ctx);

  @override
  void scale(num x, num y) => _ctx.scale(x, y);
  @override
  void clearRect(num x, num y, num w, num h) => _ctx.clearRect(x, y, w, h);
  @override
  void fillText(String text, num x, num y) => _ctx.fillText(text, x, y);
  @override
  void fillRect(num x, num y, num w, num h) => _ctx.fillRect(x, y, w, h);
  @override
  void beginPath() => _ctx.beginPath();
  @override
  void rect(num x, num y, num w, num h) => _ctx.rect(x, y, w, h);
  @override
  void clip() => _ctx.clip();
  @override
  void save() => _ctx.save();
  @override
  void restore() => _ctx.restore();
  @override
  set font(String value) => _ctx.font = value;
  @override
  set fillStyle(Object value) => _ctx.fillStyle = value;
  @override
  set strokeStyle(Object value) => _ctx.strokeStyle = value;
  @override
  set lineWidth(num value) => _ctx.lineWidth = value.toDouble();
  @override
  void moveTo(num x, num y) => _ctx.moveTo(x, y);
  @override
  void lineTo(num x, num y) => _ctx.lineTo(x, y);
  @override
  void stroke() => _ctx.stroke();
  @override
  set textBaseline(String value) => _ctx.textBaseline = value;
  @override
  void translate(num x, num y) => _ctx.translate(x, y);
  @override
  void strokeRect(num x, num y, num w, num h) => _ctx.strokeRect(x, y, w, h);

  @override
  double measureTextWidth(String text) =>
      _ctx.measureText(text).width?.toDouble() ?? 0.0;
}

class _DefaultRectangleApi implements RectangleApi {
  final html.Rectangle _rect;
  _DefaultRectangleApi(this._rect);

  @override
  double get left => _rect.left.toDouble();
  @override
  double get top => _rect.top.toDouble();
  @override
  double get width => _rect.width.toDouble();
  @override
  double get height => _rect.height.toDouble();
}

class _DefaultEventApi implements EventApi {
  final html.Event _event;
  _DefaultEventApi(this._event);

  @override
  String get key => (_event is html.KeyboardEvent)
      ? (_event as html.KeyboardEvent).key ?? ''
      : '';

  @override
  bool get shiftKey => (_event is html.MouseEvent)
      ? (_event as html.MouseEvent).shiftKey
      : false;

  @override
  bool get ctrlKey =>
      (_event is html.MouseEvent) ? (_event as html.MouseEvent).ctrlKey : false;

  @override
  bool get metaKey =>
      (_event is html.MouseEvent) ? (_event as html.MouseEvent).metaKey : false;

  @override
  void preventDefault() => _event.preventDefault();
}

class _DefaultMouseEventApi extends _DefaultEventApi implements MouseEventApi {
  _DefaultMouseEventApi(html.MouseEvent super.event);

  html.MouseEvent get _mouseEvent => _event as html.MouseEvent;

  @override
  PointApi get client => _DefaultPointApi(_mouseEvent.client);
}

class _DefaultPointApi implements PointApi {
  final html.Point _point;
  _DefaultPointApi(this._point);

  @override
  int get x => _point.x.toInt();
  @override
  int get y => _point.y.toInt();
}

// -----------------------------
// Fábricas públicas (use fora)
// -----------------------------

WindowApi createWindow() => _DefaultWindowApi();
DocumentApi createDocument() => _DefaultDocumentApi();
DivElementApi createDivElement() => _DefaultDivElementApi();
CanvasElementApi createCanvasElement({html.CanvasElement? canvas}) =>
    _DefaultCanvasElementApi(canvas: canvas);
