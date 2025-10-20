//Arquivo: C:\MyDartProjects\canvas_text_editor\lib\editor.dart
import 'dart:async';
import 'package:dart_text_editor/core/apply_inline_attributes_command.dart';
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/editor_command.dart';
import 'package:dart_text_editor/core/editor_state.dart';
import 'package:dart_text_editor/core/insert_text_command.dart';
import 'package:dart_text_editor/core/enter_command.dart';
import 'package:dart_text_editor/core/backspace_command.dart';
import 'package:dart_text_editor/core/delete_command.dart';
import 'package:dart_text_editor/core/move_caret_command.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/undo_command.dart';
import 'package:dart_text_editor/core/redo_command.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/transaction.dart';
import 'package:dart_text_editor/core/delta.dart';
import 'package:dart_text_editor/layout/page_constraints.dart';
import 'package:dart_text_editor/layout/paginator.dart';
import 'package:dart_text_editor/render/canvas_page_painter.dart';
import 'package:dart_text_editor/render/editor_theme.dart';
import 'package:dart_text_editor/render/measure_cache.dart';
import 'package:dart_text_editor/render/text_measurer.dart';
import 'package:dart_text_editor/services/clipboard_service.dart';
import 'package:dart_text_editor/util/dom_api.dart';
import 'package:dart_text_editor/util/dom_api_stub.dart'
    if (dart.library.html) 'package:dart_text_editor/util/dom_api_web.dart'
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
  late final ClipboardService clipboardService;

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
    this.paginator = paginator ?? Paginator(this.measureCache);
    painter = CanvasPagePainter(this.theme, this.measureCache, _requestPaint, this.paginator, _window);

    clipboardService = ClipboardService(
      window: _window,
      document: _document,
    );
    _setupOverlay();
    _listenToEvents();
    this.paginator.paginate(
        state.document, PageConstraints.a4(zoomLevel: state.zoomLevel));

    _resizeCanvas();
    _requestPaint();
  }

  void dispose() {
    painter?.dispose();
    _batchTimer?.cancel();
  }

  void _resizeCanvas() {
    final dpr = _window.devicePixelRatio;
    final rect = canvas.getBoundingClientRect();

    // Garante que o tamanho CSS do canvas esteja correto (pixels CSS)
    canvas.style.width = '${rect.width}px';
    canvas.style.height = '${rect.height}px';

    // Tamanho real do bitmap em pixels do dispositivo
    canvas.width = (rect.width * dpr).round();
    canvas.height = (rect.height * dpr).round();
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
      state = state.copyWith(
        typingAttributes: state.typingAttributes.copyWith(
          bold: command.bold,
          italic: command.italic,
          underline: command.underline,
          strikethrough: command.strikethrough,
          link: command.link,
          fontSize: command.fontSize,
          fontColor: command.fontColor,
          backgroundColor: command.backgroundColor,
          fontFamily: command.fontFamily,
        ),
      );
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
    final dpr = _window.devicePixelRatio;

    ctx.save();
    // Escala: tudo que desenhamos usa coordenadas em CSS px
    ctx.scale(dpr, dpr);

    // Limpa na unidade "CSS px" (canvas.width/height são em device px)
    ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);

    final pageConstraints =
        PageConstraints.a4(marginAllPt: 56.7, zoomLevel: state.zoomLevel);

    final pages = paginator.paginate(state.document, pageConstraints);
    double yOffset = 0;
    const pageGap = 20.0;

    for (final page in pages) {
      ctx.save();
      ctx.translate(0, yOffset);

      // Pinta a página + conteúdo (o painter deve respeitar margins do pageConstraints)
      painter?.paint(ctx, page, pageConstraints, state.selection);

      // Cursor (coordenadas de tela em CSS px)
      final cursorPosition = paginator.screenPos(state.selection.end);
      if (cursorPosition != null && state.selection.isCollapsed) {
        painter?.paintCursor(ctx, cursorPosition);
      }

      ctx.restore();

      // Avança para a próxima página (altura de conteúdo + margens + gap)
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
    _batchTimer = Timer(const Duration(milliseconds: 200), _finalizeBatch);
  }

  void _finalizeBatch() {
    if (!_isBatching ||
        _currentBatchDeltas == null ||
        _currentBatchDeltas!.isEmpty) {
      _isBatching = false;
      return;
    }

    final batchedDelta = Delta();
    for (final delta in _currentBatchDeltas!) {
      batchedDelta.compose(delta);
    }

    final beforeSelection = _batchSelectionBefore!;
    final afterSelection = state.selection;

    var workingDoc = _batchOriginalDocument!;
    final perDeltaInverses = <Delta>[];
    for (final delta in _currentBatchDeltas!) {
      final res = workingDoc.apply(delta);
      perDeltaInverses.add(res.inverse);
      workingDoc = res.document;
    }

    final batchedInverse = Delta();
    for (var i = perDeltaInverses.length - 1; i >= 0; i--) {
      batchedInverse.compose(perDeltaInverses[i]);
    }

    final inverseTransaction = Transaction(
        batchedDelta, batchedInverse, beforeSelection, afterSelection,
        subDeltas: List.from(_currentBatchDeltas!),
        subInverses: perDeltaInverses.reversed.toList());
    final newUndoStack = List<Transaction>.from(state.undoStack)
      ..add(inverseTransaction);

    state = state.copyWith(undoStack: newUndoStack, redoStack: []);

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
      ..tabIndex = 0
      ..style.position = 'absolute'
      ..style.opacity = '0'
      ..style.pointerEvents = 'auto' //Garante que a overlay capture eventos
      ..style.zIndex = '1'
      ..style.setProperty('outline', 'none');
    _document.body!.append(_overlay);
    _overlay.focus();
  }

  void _listenToEvents() {
    int clampIdx(int v, int min, int max) =>
        v < min ? min : (v > max ? max : v);

    _window.onResize.listen((_) {
      print('[RESIZE]');
      _syncOverlay();
      _resizeCanvas();
      _requestPaint();
    });

    _window.onScroll.listen((_) {
      print('[SCROLL]');
      _syncOverlay();
      _requestPaint();
    });

    _overlay.onKeyDown.listen((event) {
      bool handled = true;
      print(
          '[KEY] key=${event.key} ctrl=${event.ctrlKey} meta=${event.metaKey} shift=${event.shiftKey}');
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
      } else if (event.key == 'Home') {
        execute(MoveCaretCommand(CaretMovement.lineStart, paginator,
            extend: event.shiftKey));
      } else if (event.key == 'End') {
        execute(MoveCaretCommand(CaretMovement.lineEnd, paginator,
            extend: event.shiftKey));
      } else if (event.ctrlKey || event.metaKey) {
        if (event.key == 'z') {
          execute(UndoCommand());
        } else if (event.key == 'y' || (event.shiftKey && event.key == 'z')) {
          execute(RedoCommand());
        } else if (event.key == 'c') {
          _handleCopy();
          handled = true;
        } else if (event.key == 'v') {
          _handlePaste();
          handled = true;
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
      if (event.button != 0) return;
      _overlay.focus();
      final rect = canvas.getBoundingClientRect();
      final zoom = state.zoomLevel;
      final x = (event.client.x - rect.left) / zoom;
      final y = (event.client.y - rect.top) / zoom;
      print(
          '[MOUSEDOWN] client=(${event.client.x},${event.client.y}) rect=(${rect.left},${rect.top}) zoom=$zoom logical=($x,$y)');
      final position =
          paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
      print('[MOUSEDOWN] pos node=${position?.node} off=${position?.offset}');
      if (position != null) {
        if (position.node >= 0 && position.node < state.document.nodes.length) {
          final n = state.document.nodes[position.node];
          if (n is ParagraphNode) {
            final t = n.text;
            final o = clampIdx(position.offset, 0, t.length);
            final ch = (o >= 0 && o < t.length) ? t[o] : '';
            final s = clampIdx(o - 10, 0, t.length);
            final e = clampIdx(o + 10, 0, t.length);
            final around = t.substring(s, e);
            print('[MOUSEDOWN] char="$ch" around="$around"');
          }
        }
        paginator.desiredX = null;
        _dragAnchorPosition = position;
        _isDragging = true;
        paginator.keyboardAnchor = position;
        state = state.copyWith(selection: Selection.collapsed(position));
        _requestPaint();
      }
      event.preventDefault();
    });

    _overlay.onMouseMove.listen((event) {
      if (_isDragging && _dragAnchorPosition != null) {
        final rect = canvas.getBoundingClientRect();
        final zoom = state.zoomLevel;
        final x = (event.client.x - rect.left) / zoom;
        final y = (event.client.y - rect.top) / zoom;
        final currentPosition =
            paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
        print(
            '[MOUSEMOVE] logical=($x,$y) anchor=${_dragAnchorPosition?.offset} -> curr=${currentPosition?.offset}');
        if (currentPosition != null) {
          state = state.copyWith(
              selection: Selection(_dragAnchorPosition!, currentPosition));
          _requestPaint();
        }
      }
    });

    _overlay.onMouseUp.listen((event) {
      print('[MOUSEUP]');
      _isDragging = false;
      _dragAnchorPosition = null;
    });

    _overlay.onDoubleClick.listen((event) {
      final rect = canvas.getBoundingClientRect();
      final zoom = state.zoomLevel;
      final x = (event.client.x - rect.left) / zoom;
      final y = (event.client.y - rect.top) / zoom;
      print(
          '[DOUBLECLICK] client=(${event.client.x},${event.client.y}) rect=(${rect.left},${rect.top}) zoom=$zoom logical=($x,$y)');
      final position =
          paginator.getPositionFromScreen(x.toDouble(), y.toDouble());
      print('[DOUBLECLICK] pos node=${position?.node} off=${position?.offset}');
      if (position != null) {
        final selectionAtClick = Selection.collapsed(position);
        final newSelection =
            selectionAtClick.expandToWordBoundaries(state.document);
        if (newSelection.start.node >= 0 &&
            newSelection.start.node < state.document.nodes.length) {
          final node = state.document.nodes[newSelection.start.node];
          if (node is ParagraphNode) {
            final text = node.text;
            final s = clampIdx(newSelection.start.offset, 0, text.length);
            final e = clampIdx(newSelection.end.offset, 0, text.length);
            final selected = s < e ? text.substring(s, e) : '';
            print('[DOUBLECLICK] selection "$selected" [$s,$e]');
          }
        }
        state = state.copyWith(selection: newSelection);
        _requestPaint();
      }
    });

    canvas.onClick.listen((event) {
      _overlay.focus();
    });
  }

  void _handleCopy() {
    clipboardService.copy(state);
  }

  void _handlePaste() async {
    final text = await clipboardService.paste();
    if (text != null && text.isNotEmpty) {
      execute(InsertTextCommand(text));
    }
  }
}
