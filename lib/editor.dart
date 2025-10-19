import 'dart:async';
import 'package:canvas_text_editor/core/apply_inline_attributes_command.dart';
import 'package:canvas_text_editor/core/document_model.dart';
import 'package:canvas_text_editor/core/editor_command.dart';
import 'package:canvas_text_editor/core/editor_state.dart';
import 'package:canvas_text_editor/core/insert_text_command.dart';
import 'package:canvas_text_editor/core/enter_command.dart';
import 'package:canvas_text_editor/core/backspace_command.dart';
import 'package:canvas_text_editor/core/delete_command.dart';
import 'package:canvas_text_editor/core/move_caret_command.dart';
import 'package:canvas_text_editor/core/undo_command.dart';
import 'package:canvas_text_editor/core/redo_command.dart';
import 'package:canvas_text_editor/core/position.dart';
import 'package:canvas_text_editor/core/selection.dart';
import 'package:canvas_text_editor/core/transaction.dart';
import 'package:canvas_text_editor/core/delta.dart';
import 'package:canvas_text_editor/layout/page_constraints.dart';
import 'package:canvas_text_editor/layout/paginator.dart';
import 'package:canvas_text_editor/render/canvas_page_painter.dart';
import 'package:canvas_text_editor/render/editor_theme.dart';
import 'package:canvas_text_editor/render/measure_cache.dart';
import 'package:canvas_text_editor/render/text_measurer.dart';
import 'package:canvas_text_editor/util/dom_api.dart';
import 'package:canvas_text_editor/util/dom_api_stub.dart'
    if (dart.library.html) 'package:canvas_text_editor/util/dom_api_web.dart'
    as dom_api;

class Editor {
  final CanvasElementApi canvas;
  final CanvasRenderingContext2DApi ctx;
  final EditorTheme theme;
  late final Paginator paginator;
  CanvasPagePainter? painter;
  final DivElementApi _overlay;
  late final MeasureCache measureCache;
  final WindowApi _window;
  final DocumentApi _document;

  EditorState state;

  Position? _dragAnchorPosition;
  bool _isDragging = false;

  List<Delta>? _currentBatchDeltas;
  Timer? _batchTimer;
  bool _isBatching = false;
  DocumentModel? _batchOriginalDocument;
  Selection? _batchSelectionBefore;

  bool _animationFrameRequested = false;

  Editor(this.canvas, DocumentModel document,
      {EditorTheme? theme,
      WindowApi? window,
      DocumentApi? documentApi,
      Paginator? paginator,
      DivElementApi? overlay,
      MeasureCache? measureCache,
      double zoomLevel = 1.0})
      : ctx = canvas.context2D,
        theme = theme ?? EditorTheme(),
        state = EditorState(
            document: document,
            selection: Selection.collapsed(const Position(0, 0)),
            zoomLevel: zoomLevel),
        _overlay = overlay ?? dom_api.createDivElement(),
        _window = window ?? dom_api.createWindow(),
        _document = documentApi ?? dom_api.createDocument() {
    this.measureCache =
        measureCache ?? MeasureCache(TextMeasurer(canvas.context2D));
    this.paginator = paginator ?? Paginator(this.measureCache);  // Initialize paginator first
    painter = CanvasPagePainter(this.theme, this.measureCache, _requestPaint);
    _setupOverlay();
    _listenToEvents();
    this.paginator.paginate(
        state.document, PageConstraints.a4(zoomLevel: state.zoomLevel));
    _requestPaint();
  }

  void dispose() {
    painter?.dispose();
    _batchTimer?.cancel();
  }

  void execute(EditorCommand command) {
    if (_isBatching &&
        !(command is BackspaceCommand ||
            command is DeleteCommand ||
            command is InsertTextCommand)) {
      _finalizeBatch();
    }

    if (command is ApplyInlineAttributesCommand &&
        state.selection.isCollapsed) {
      final newTypingAttributes =
          state.typingAttributes.merge(command.attributes);
      state = state.copyWith(typingAttributes: newTypingAttributes);
      return;
    }

    if (command is UndoCommand) {
      undo();
      return;
    }
    if (command is RedoCommand) {
      redo();
      return;
    }

    if (command is BackspaceCommand ||
        command is DeleteCommand ||
        command is InsertTextCommand) {
      _startBatch(command);
      return;
    }

    final transaction = command.exec(state);

    if (transaction.delta.isEmpty) {
      state = state.copyWith(selection: transaction.after);
      _requestPaint();
      return;
    }

    final applyResult = state.document
        .apply(transaction.delta, beforeCaret: state.selection.start);
    final newDocument = applyResult.document;
    final inverse = applyResult.inverse;

    // Transaction(delta, inverseDelta, before, after)
    final inverseTransaction = Transaction(
        transaction.delta, inverse, transaction.before, transaction.after);

    const maxUndo = 200;
    final newUndoStack = List<Transaction>.from(state.undoStack)
      ..add(inverseTransaction);
    if (newUndoStack.length > maxUndo) newUndoStack.removeAt(0);

    state = state.copyWith(
      document: newDocument,
      selection: applyResult.newCaret != null
          ? Selection.collapsed(applyResult.newCaret!)
          : transaction.after,
      undoStack: newUndoStack,
      redoStack: [],
    );
    _requestPaint();
  }

  void undo() {
    if (_isBatching) _finalizeBatch();
    if (state.undoStack.isEmpty) return;

    final newUndoStack = List<Transaction>.from(state.undoStack);
    final transactionToUndo = newUndoStack.removeLast();
    // If this transaction contains subInverses (batched per-delta inverses),
    // apply them in order to revert the original sequence of operations.
    DocumentModel newDocument = state.document;
    if (transactionToUndo.subInverses != null &&
        transactionToUndo.subInverses!.isNotEmpty) {
      var working = state.document;
      for (final inv in transactionToUndo.subInverses!) {
        final res = working.apply(inv);
        working = res.document;
      }
      newDocument = working;
    } else {
      final applyResult = state.document.apply(transactionToUndo.inverseDelta);
      newDocument = applyResult.document;
    }

    final newRedoStack = List<Transaction>.from(state.redoStack)
      ..add(transactionToUndo);

    state = state.copyWith(
      document: newDocument,
      selection: transactionToUndo.before,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
    _requestPaint();
  }

  void redo() {
    if (_isBatching) _finalizeBatch();
    if (state.redoStack.isEmpty) return;

    final newRedoStack = List<Transaction>.from(state.redoStack);
    final transactionToRedo = newRedoStack.removeLast();
    // If the transaction was a batched transaction with subDeltas, replay
    // each sub-delta in order; otherwise apply the single delta.
    DocumentModel newDocument = state.document;
    if (transactionToRedo.subDeltas != null &&
        transactionToRedo.subDeltas!.isNotEmpty) {
      var working = state.document;
      for (final d in transactionToRedo.subDeltas!) {
        final res = working.apply(d);
        working = res.document;
      }
      newDocument = working;
    } else {
      final applyResult = state.document.apply(transactionToRedo.delta);
      newDocument = applyResult.document;
    }

    final newUndoStack = List<Transaction>.from(state.undoStack)
      ..add(transactionToRedo);

    state = state.copyWith(
      document: newDocument,
      selection: transactionToRedo.after,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
    _requestPaint();
  }

  void paint() {
    _requestPaint();
  }

  void _requestPaint() {
    if (!_animationFrameRequested) {
      _animationFrameRequested = true;
      _window.requestAnimationFrame(_onAnimationFrame);
    }
  }

  void _onAnimationFrame(num highResTime) {
    _animationFrameRequested = false;
    _doPaint();
  }

  void _doPaint() {
    _syncOverlay(); // <— NOVO: caso o layout/scroll tenha mudado
    final dpr = _window.devicePixelRatio;
    final rect = canvas.getBoundingClientRect();
    canvas.width = (rect.width * dpr).round();
    canvas.height = (rect.height * dpr).round();
    ctx.save();
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, canvas.width.toDouble(), canvas.height.toDouble());

    final pageConstraints =
        PageConstraints.a4(marginAllPt: 56.7, zoomLevel: state.zoomLevel);

    final pages = paginator.paginate(state.document, pageConstraints);

    double yOffset = 0;
    const pageGap = 20.0;

    for (final page in pages) {
      ctx.save();
      ctx.translate(0, yOffset);
      painter?.paint(ctx, page, pageConstraints, state.selection);
      final cursorPosition = paginator.screenPos(state.selection.end);
      if (cursorPosition != null && state.selection.isCollapsed) {
        painter?.paintCursor(ctx, cursorPosition);
      }
      ctx.restore();
      yOffset += pageConstraints.height +
          pageConstraints.marginTop +
          pageConstraints.marginBottom +
          pageGap;
    }

    ctx.restore();
  }

  void _startBatch(EditorCommand command) {
    if (!_isBatching) {
      _isBatching = true;
      _batchOriginalDocument = state.document;
      _currentBatchDeltas = <Delta>[];
      _batchSelectionBefore = state.selection;
    }

    final transaction = command.exec(state);
    _currentBatchDeltas!.add(transaction.delta);

    final applyResult = state.document
        .apply(transaction.delta, beforeCaret: state.selection.start);
    state = state.copyWith(
      document: applyResult.document,
      selection: applyResult.newCaret != null
          ? Selection.collapsed(applyResult.newCaret!)
          : transaction.after,
    );
    _requestPaint();

    _batchTimer?.cancel();
    // Use a 200ms batching window to match the test expectations and create
    // a responsive undo grouping for quick typing/delete sequences.
    _batchTimer = Timer(const Duration(milliseconds: 200), _finalizeBatch);
  }

  void _finalizeBatch() {
    if (!_isBatching ||
        _currentBatchDeltas == null ||
        _currentBatchDeltas!.isEmpty) {
      _isBatching = false;
      return;
    }

    // Compose the batched delta (in chronological order)
    final batchedDelta = Delta();
    for (final delta in _currentBatchDeltas!) {
      batchedDelta.compose(delta);
    }

    final beforeSelection = _batchSelectionBefore!;
    final afterSelection = state.selection;

    // Apply each delta sequentially to a working copy of the original
    // document and collect per-delta inverses. Then compose those
    // inverses in reverse order to form the overall inverse for the
    // entire batched operation. This correctly accounts for shifting
    // offsets between deltas.
    var workingDoc = _batchOriginalDocument!;
    final perDeltaInverses = <Delta>[];
    for (final delta in _currentBatchDeltas!) {
      final res = workingDoc.apply(delta);
      perDeltaInverses.add(res.inverse);
      workingDoc = res.document;
    }
    try {
      for (var i = 0; i < perDeltaInverses.length; i++) {
        print(
            '[DEBUG perDeltaInverse $i] ops=${perDeltaInverses[i].ops.map((o) => o.toString()).toList()} length=${perDeltaInverses[i].length}');
      }
    } catch (_) {}

    final batchedInverse = Delta();
    for (var i = perDeltaInverses.length - 1; i >= 0; i--) {
      batchedInverse.compose(perDeltaInverses[i]);
    }
    try {
      print(
          '[DEBUG _finalizeBatch] batchedDelta.ops=${batchedDelta.ops.map((o) => o.toString()).toList()}');
      print(
          '[DEBUG _finalizeBatch] batchedInverse.ops=${batchedInverse.ops.map((o) => o.toString()).toList()}');
    } catch (_) {}

    final inverseTransaction = Transaction(
        batchedDelta, batchedInverse, beforeSelection, afterSelection,
        subDeltas: List.from(_currentBatchDeltas!),
        subInverses: perDeltaInverses.reversed.toList());

    final newUndoStack = List<Transaction>.from(state.undoStack)
      ..add(inverseTransaction);

    state = state.copyWith(undoStack: newUndoStack, redoStack: []);
    try {
      print(
          '[DEBUG _finalizeBatch] document after batch=${state.document.nodes.map((n) => n.runtimeType.toString()).join('|')}');
    } catch (_) {}

    _isBatching = false;
    _batchTimer?.cancel();
    _currentBatchDeltas = null;
    _batchOriginalDocument = null;
    _batchSelectionBefore = null;
  }

  void _syncOverlay() {
    final r = canvas.getBoundingClientRect();
    _overlay
      ..style.left = '${r.left + _window.scrollX}px'
      ..style.top = '${r.top + _window.scrollY}px'
      ..style.width = '${r.width}px'
      ..style.height = '${r.height}px';
  }

  void _setupOverlay() {
    _syncOverlay();
    _overlay
      ..contentEditable = 'true'
      ..tabIndex = 0 // <— NOVO: garante foco programático
      ..style.position = 'absolute'
      ..style.opacity = '0'
      ..style.zIndex = '1'
      ..style.setProperty('outline', 'none');
    _document.body!.append(_overlay);

    // foca já no início para digitar imediatamente
    _overlay.focus();
  }

  void _listenToEvents() {
    _window.onResize.listen((_) {
      _syncOverlay();
      _requestPaint();
    });
    _window.onScroll.listen((_) {
      _syncOverlay();
      _requestPaint();
    });

    _overlay.onKeyDown.listen((event) {
      bool handled = true;
      if (event.key == 'Enter') {
        execute(EnterCommand());
      } else if (event.key == 'Backspace') {
        execute(BackspaceCommand());
      } else if (event.key == 'Delete') {
        execute(DeleteCommand());
      } else if (event.key.length == 1 && !event.ctrlKey && !event.metaKey) {
        execute(InsertTextCommand(event.key));
      } else if (event.key.startsWith('Arrow')) {
        CaretMovement dir;
        if (event.ctrlKey && event.key == 'ArrowLeft') {
          dir = CaretMovement.wordLeft;
        } else if (event.ctrlKey && event.key == 'ArrowRight') {
          dir = CaretMovement.wordRight;
        } else if (event.key == 'ArrowLeft') {
          dir = CaretMovement.left;
        } else if (event.key == 'ArrowRight') {
          dir = CaretMovement.right;
        } else if (event.key == 'ArrowUp') {
          dir = CaretMovement.up;
        } else if (event.key == 'ArrowDown') {
          dir = CaretMovement.down;
        } else {
          return;
        }
        execute(MoveCaretCommand(dir, paginator, extend: event.shiftKey));
      } else if (event.ctrlKey || event.metaKey) {
        if (event.key == 'z') {
          execute(UndoCommand());
        } else if (event.key == 'y' || (event.shiftKey && event.key == 'z')) {
          execute(RedoCommand());
        } else {
          handled = false;
        }
      } else {
        handled = false;
      }

      if (handled) {
        event.preventDefault();
      }
    });

    _overlay.onMouseDown.listen((event) {
      _overlay.focus(); // <— NOVO
      final rect = canvas.getBoundingClientRect();
      final x = (event.client.x - rect.left);
      final y = (event.client.y - rect.top);
      final position =
          paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
      if (position != null) {
        _dragAnchorPosition = position;
        _isDragging = true;
        state = state.copyWith(selection: Selection.collapsed(position));
        _requestPaint();
      }
      event.preventDefault();
    });

    _overlay.onMouseMove.listen((event) {
      if (_isDragging && _dragAnchorPosition != null) {
        final rect = canvas.getBoundingClientRect();
        final x = (event.client.x - rect.left);
        final y = (event.client.y - rect.top);
        final currentPosition =
            paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
        if (currentPosition != null) {
          state = state.copyWith(
              selection: Selection(_dragAnchorPosition!, currentPosition));
          _requestPaint();
        }
      }
    });

    _overlay.onMouseUp.listen((event) {
      _isDragging = false;
      _dragAnchorPosition = null;
    });

    canvas.onClick.listen((event) {
      _overlay.focus();
    });
  }
}
