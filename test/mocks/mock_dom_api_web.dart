import 'package:canvas_text_editor/util/dom_api.dart';
import 'manual_dom_api_mocks.dart';

// Mock implementations for the factory methods in dom_api_web.dart
// These are used in tests to provide controlled mock objects.

WindowApi createWindow() => MockWindowApi();
DocumentApi createDocument() => MockDocumentApi();
DivElementApi createDivElement() => MockDivElementApi();
CanvasElementApi createCanvasElement({dynamic canvas}) => MockCanvasElementApi();