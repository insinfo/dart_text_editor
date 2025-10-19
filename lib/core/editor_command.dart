import 'package:dart_text_editor/core/editor_state.dart';

import 'package:dart_text_editor/core/transaction.dart';

abstract class EditorCommand {
  /// Returns a [Transaction] describing the change produced by this command.
  Transaction exec(EditorState state);
}
