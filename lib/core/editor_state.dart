//C:\MyDartProjects\canvas_text_editor\lib\core\editor_state.dart
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';

class EditorState {
  final DocumentModel document;
  final Selection selection;
  final List<Transaction> undoStack;
  final List<Transaction> redoStack;
  final double zoomLevel;
  final InlineAttributes typingAttributes;

  EditorState({
    required this.document,
    required this.selection,
    this.undoStack = const [],
    this.redoStack = const [],
    this.zoomLevel = 1.0,
    this.typingAttributes = const InlineAttributes(),
  });

  EditorState copyWith({
    DocumentModel? document,
    Selection? selection,
    List<Transaction>? undoStack,
    List<Transaction>? redoStack,
    double? zoomLevel,
    InlineAttributes? typingAttributes,
  }) {
    return EditorState(
      document: document ?? this.document,
      selection: selection ?? this.selection,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      typingAttributes: typingAttributes ?? this.typingAttributes,
    );
  }
}
