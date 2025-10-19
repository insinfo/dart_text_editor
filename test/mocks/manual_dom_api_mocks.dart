// Arquivo: test/mocks/manual_dom_api_mocks.dart (COMPLETO E CORRIGIDO)
import 'dart:async';
import 'package:dart_text_editor/util/dom_api.dart';

// --- MOCKS DE ELEMENTOS E CONTEXTO ---

// Mock CanvasElement and CanvasRenderingContext2D


class MockCanvasElementApi implements CanvasElementApi {
  @override
  int width = 800;
  @override
  int height = 600;
  @override
  final CanvasRenderingContext2DApi context2D =
      MockCanvasRenderingContext2DApi();

  MockCanvasElementApi({this.width = 800, this.height = 600});

  @override
  RectangleApi getBoundingClientRect() => MockRectangleApi();

  @override
  Stream<MouseEventApi> get onClick => Stream<MouseEventApi>.empty();

  // CORREÇÃO: Implementação ausente adicionada.
  @override
  Stream<MouseEventApi> get onDoubleClick => Stream<MouseEventApi>.empty();
}

class MockCanvasRenderingContext2DApi implements CanvasRenderingContext2DApi {
  @override
  String font = '';
  @override
  Object fillStyle = '';
  @override
  Object strokeStyle = '';
  @override
  num lineWidth = 1;
  @override
  String textBaseline = 'alphabetic';

  @override
  void scale(num x, num y) {}
  @override
  void clearRect(num x, num y, num w, num h) {}
  @override
  void fillText(String text, num x, num y) {}
  @override
  void fillRect(num x, num y, num w, num h) {}
  @override
  void beginPath() {}
  @override
  void rect(num x, num y, num w, num h) {}
  @override
  void clip() {}
  @override
  void save() {}
  @override
  void restore() {}
  @override
  void moveTo(num x, num y) {}
  @override
  void lineTo(num x, num y) {}
  @override
  void stroke() {}
  @override
  void translate(num x, num y) {}
  @override
  void strokeRect(num x, num y, num w, num h) {}
  // Largura de caractere mockada
  @override
  double measureTextWidth(String text) => text.length * 8.0;
}

class MockDivElementApi implements DivElementApi {
  final StreamController<MouseEventApi> _onMouseDownController =
      StreamController<MouseEventApi>.broadcast();
  final StreamController<MouseEventApi> _onMouseMoveController =
      StreamController<MouseEventApi>.broadcast();
  final StreamController<MouseEventApi> _onMouseUpController =
      StreamController<MouseEventApi>.broadcast();
  final StreamController<EventApi> _onKeyDownController =
      StreamController<EventApi>.broadcast();
  final StreamController<EventApi> _onKeyUpController =
      StreamController<EventApi>.broadcast();
  final StreamController<MouseEventApi> _onClickController =
      StreamController<MouseEventApi>.broadcast();
  final StreamController<MouseEventApi> _onDoubleClickController =
      StreamController<MouseEventApi>.broadcast();

  @override
  Stream<MouseEventApi> get onMouseDown => _onMouseDownController.stream;
  @override
  Stream<MouseEventApi> get onMouseMove => _onMouseMoveController.stream;
  @override
  Stream<MouseEventApi> get onMouseUp => _onMouseUpController.stream;
  @override
  Stream<EventApi> get onKeyDown => _onKeyDownController.stream;
  @override
  Stream<EventApi> get onKeyUp => _onKeyUpController.stream;
  @override
  Stream<MouseEventApi> get onClick => _onClickController.stream;
  @override
  Stream<MouseEventApi> get onDoubleClick => _onDoubleClickController.stream;

  @override
  String contentEditable = 'false';

  @override
  void focus() {}

  @override
  final CssStyleDeclarationApi style = MockCssStyleDeclarationApi();

  @override
  void append(NodeApi node) {}

  @override
  int? tabIndex;

  // Métodos para controlar os eventos nos testes
  void triggerMouseDown(MouseEventApi event) =>
      _onMouseDownController.add(event);
  void triggerMouseMove(MouseEventApi event) =>
      _onMouseMoveController.add(event);
  void triggerMouseUp(MouseEventApi event) => _onMouseUpController.add(event);
  void triggerKeyDown(EventApi event) => _onKeyDownController.add(event);
  void triggerDoubleClick(MouseEventApi event) =>
      _onDoubleClickController.add(event);
}

class MockCssStyleDeclarationApi implements CssStyleDeclarationApi {
  @override
  String position = '';
  @override
  String left = '';
  @override
  String top = '';
  @override
  String width = '';
  @override
  String height = '';
  @override
  String opacity = '';
  @override
  String zIndex = '';

  @override
  void setProperty(String name, String value) {}
}

// --- MOCKS DE API DO NAVEGADOR ---

class MockWindowApi implements WindowApi {
  @override
  double get devicePixelRatio => 1.0;
  @override
  double get scrollX => 0.0;
  @override
  double get scrollY => 0.0;

  @override
  void requestAnimationFrame(void Function(num highResTime) callback) {
    Future.microtask(() => callback(0));
  }

  @override
  Stream<EventApi> get onResize => Stream<EventApi>.empty();
  @override
  Stream<EventApi> get onScroll => Stream<EventApi>.empty();
}

class MockDocumentApi implements DocumentApi {
  @override
  final BodyElementApi? body = MockBodyElementApi();
}

class MockBodyElementApi implements BodyElementApi {
  @override
  void append(NodeApi node) {}
}

// --- MOCKS DE GEOMETRIA E EVENTOS ---

class MockRectangleApi implements RectangleApi {
  @override
  double get left => 0;
  @override
  double get top => 0;
  @override
  double get width => 800;
  @override
  double get height => 600;
}

class MockEventApi implements EventApi {
  @override
  final String key;
  @override
  final bool shiftKey;
  @override
  final bool ctrlKey;
  @override
  final bool metaKey;

  MockEventApi(
      {this.key = '',
      this.shiftKey = false,
      this.ctrlKey = false,
      this.metaKey = false});

  @override
  void preventDefault() {}
}

class MockMouseEventApi implements MouseEventApi {
  @override
  final PointApi client;

  // Implementando propriedades de EventApi
  @override
  final String key;
  @override
  final bool shiftKey;
  @override
  final bool ctrlKey;
  @override
  final bool metaKey;

  MockMouseEventApi({
    required int clientX,
    required int clientY,
    this.key = '',
    this.shiftKey = false,
    this.ctrlKey = false,
    this.metaKey = false,
  }) : client = MockPointApi(clientX, clientY);

  @override
  void preventDefault() {}
}

class MockPointApi implements PointApi {
  @override
  final int x;
  @override
  final int y;

  MockPointApi(this.x, this.y);
}

class MockCanvasRenderingContext2D implements CanvasRenderingContext2DApi {
  @override
  void scale(num x, num y) {}
  @override
  void clearRect(num x, num y, num w, num h) {}
  @override
  void fillText(String text, num x, num y) {}
  @override
  void fillRect(num x, num y, num w, num h) {}
  @override
  void beginPath() {}
  @override
  void rect(num x, num y, num w, num h) {}
  @override
  void clip() {}
  @override
  void save() {}
  @override
  void restore() {}
  @override
  set font(String value) {}
  @override
  set fillStyle(Object value) {}
  @override
  set strokeStyle(Object value) {}
  @override
  set lineWidth(num value) {}
  @override
  void moveTo(num x, num y) {}
  @override
  void lineTo(num x, num y) {}
  @override
  void stroke() {}
  @override
  set textBaseline(String value) {}
  @override
  void translate(num x, num y) {}
  @override
  void strokeRect(num x, num y, num w, num h) {}
  @override
  double measureTextWidth(String text) => text.length * 8.0; // Mock measurement
}

class MockRectangle implements RectangleApi {
  @override
  double get left => 0;
  @override
  double get top => 0;
  @override
  double get width => 800;
  @override
  double get height => 600;
}
