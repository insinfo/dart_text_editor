import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';

const mainDartString = r'''
import 'package:dart_text_editor/core/document_model.dart';
import 'package:dart_text_editor/core/paragraph_node.dart';
import 'package:dart_text_editor/core/position.dart';
import 'package:dart_text_editor/core/selection.dart';
import 'package:dart_text_editor/core/text_run.dart';
import 'package:dart_text_editor/editor.dart';
import 'package:dart_text_editor/core/inline_attributes.dart';
import 'package:dart_text_editor/util/dom_api_web.dart' as dom_api_web;
import 'dart:js_util' as js_util;
import 'package:web/web.dart' as html;

void main() {
  final htmlCanvas = html.document.querySelector('canvas') as html.HTMLCanvasElement;
  final canvasElementApi = dom_api_web.createCanvasElement(canvas: htmlCanvas);
  
  final doc = DocumentModel([
    ParagraphNode([
      TextRun(0, 'Hello, world! This is a simple text editor built with Dart and Canvas. Try typing something. This is a new line with some ', const InlineAttributes()),
      TextRun(136, 'bold', const InlineAttributes(bold: true)),
      TextRun(140, ' text.', const InlineAttributes()),
    ]),
    ParagraphNode([ TextRun(0, 'This is another paragraph.', const InlineAttributes()), ]),
  ]);

  final editor = Editor(canvasElementApi, doc);
  editor.paint();

  String nodeText(int i) => (editor.state.document.nodes[i] as ParagraphNode).text;

  Map<String, dynamic> getSnapshot() {
    final sel = editor.state.selection;
    return {
      'selection': {
        'startNode': sel.start.node, 'startOffset': sel.start.offset,
        'endNode': sel.end.node, 'endOffset': sel.end.offset,
        'isCollapsed': sel.isCollapsed,
      }
    };
  }
  
  String getSelectedText() {
    final s = editor.state.selection;
    if (s.isCollapsed) return '';
    final node = editor.state.document.nodes[s.start.node] as ParagraphNode;
    return node.text.substring(s.start.offset, s.end.offset);
  }

  void selectRange(int node, int start, int end) {
    editor.state = editor.state.copyWith(selection: Selection(Position(node, start), Position(node, end)));
    editor.paint();
  }

  js_util.setProperty(html.window, '__getSnapshot', js_util.allowInterop(getSnapshot));
  js_util.setProperty(html.window, '__getDocText', js_util.allowInterop(nodeText));
  js_util.setProperty(html.window, '__getSelectedText', js_util.allowInterop(getSelectedText));
  js_util.setProperty(html.window, '__selectRange', js_util.allowInterop(selectRange));
}
''';

const indexHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Editor Test</title>
  <link rel="icon" href="data:,">
</head>
<body>
  <canvas width="800" height="600"></canvas>
  <script defer src="main.dart.js"></script>
</body>
</html>
''';

class _ServeArgs {
  final String dir;
  final SendPort sendPort;
  final int? port;
  _ServeArgs(this.dir, this.sendPort, {this.port});
}

void _serverIsolate(_ServeArgs args) async {
  final handler = createStaticHandler(args.dir, defaultDocument: 'index.html');
  final server = await io.serve(handler, '127.0.0.1', args.port ?? 0);
  print('_serverIsolate ${server.address.host}:${server.port}');
  final control = ReceivePort();
  args.sendPort
      .send({'port': args.port ?? server.port, 'control': control.sendPort});
  await for (final msg in control) {
    if (msg == 'close') {
      await server.close(force: true);
      control.close();
      break;
    }
  }
}

void main() {
  group('Editor UI Interaction Tests', () {
    late String baseUrl;
    Browser? browser;
    Page? page;
    final buildDir = Directory('build_test');
    late SendPort srvCtl;

    setUpAll(() async {
      if (buildDir.existsSync()) buildDir.deleteSync(recursive: true);
      buildDir.createSync(recursive: true);
      File(p.join(buildDir.path, 'index.html')).writeAsStringSync(indexHtml);
      final mainPath = p.join(buildDir.path, 'main.dart');
      File(mainPath).writeAsStringSync(mainDartString);
      print('compilando main.dart.js');

      final compile = await Process.run('dart', [
        'compile',
        'js',
        '-O1',
        '-o',
        p.join(buildDir.path, 'main.dart.js'),
        mainPath
      ]);
      if (compile.exitCode != 0) {
        throw Exception('Dart compile failed:\n${compile.stderr}');
      }

      final rp = ReceivePort();
      await Isolate.spawn(
          _serverIsolate, _ServeArgs(buildDir.path, rp.sendPort, port: 5000));
      final init = await rp.first as Map;
      srvCtl = init['control'] as SendPort;
      baseUrl = 'http://127.0.0.1:5000';
      print('_serverIsolate baseUrl $baseUrl');

      browser = await puppeteer.launch(headless: true);
      await browser!.defaultBrowserContext
          .overridePermissions(baseUrl, [PermissionType.clipboardReadWrite]);
    });

    tearDownAll(() async {
      await browser?.close();
      srvCtl.send('close');
    });

    setUp(() async {
      page = await browser!.newPage();
      await page!.goto(baseUrl, wait: Until.networkIdle);
      await page!.waitForSelector('canvas');
    });

    tearDown(() => page?.close());

    Future<Map<String, dynamic>> getSnapshot() async {
      await Future.delayed(
          const Duration(milliseconds: 50)); // Delay para sincronia
      final result = await page!.evaluate<Map>('() => window.__getSnapshot()');
      return Map<String, dynamic>.from(result);
    }

    test('Double click on a word should select it correctly', () async {
      final canvasBox = await page!.evaluate<Map>(
          '() => document.querySelector("canvas").getBoundingClientRect().toJSON()');

      final x = (canvasBox['x'] as num) + 56.7 + (7.5 * 7);
      final y = (canvasBox['y'] as num) + 40;

      await page!.mouse.click(Point(x, y), clickCount: 2);
      await Future.delayed(
          const Duration(milliseconds: 200)); // Espera processamento

      final selectedText =
          await page!.evaluate<String>('() => window.__getSelectedText()');
      expect(selectedText, equals('bold'));
    });

    test('Ctrl+C should copy text without deleting it', () async {
      await page!
          .evaluate("window.__selectRange(0, 7, 13)"); // Seleciona "world!"

      final beforeText =
          await page!.evaluate<String>('() => window.__getDocText(0)');

      await page!.keyboard.down(Key.control);
      await page!.keyboard.press(Key.keyC);
      await page!.keyboard.up(Key.control);

      await Future.delayed(const Duration(milliseconds: 100));

      final afterText =
          await page!.evaluate<String>('() => window.__getDocText(0)');
      expect(afterText, equals(beforeText));

      final clipboardText =
          await page!.evaluate<String>('() => navigator.clipboard.readText()');
      expect(clipboardText, 'world!');
    });

    test('Shift+Arrow expands and collapses selection correctly', () async {
      final r = await page!.evaluate<Map>(
          '() => document.querySelector("canvas").getBoundingClientRect().toJSON()');
      await page!.mouse
          .click(Point((r['x'] as num) + 100, (r['y'] as num) + 20));

      await page!.keyboard.down(Key.shift);
      await page!.keyboard.press(Key.arrowRight);
      await page!.keyboard.press(Key.arrowRight);
      await page!.keyboard.up(Key.shift);

      var snapshot = await getSnapshot();
      expect(snapshot['selection']['isCollapsed'], isFalse);
      final selectionBeforeCollapse = snapshot['selection'];

      await page!.keyboard.press(Key.arrowRight);

      snapshot = await getSnapshot();
      expect(snapshot['selection']['isCollapsed'], isTrue);
      expect(snapshot['selection']['startOffset'],
          selectionBeforeCollapse['endOffset']);
    });

    test('Double click on "H" selects only "Hello"', () async {
      final canvasBox = await page!.evaluate<Map>(
          '() => document.querySelector("canvas").getBoundingClientRect().toJSON()');
      final x = (canvasBox['x'] as num) + 56.7 + 10; // Aproximadamente na "H"
      final y = (canvasBox['y'] as num) + 10; // Linha 0
      await page!.mouse.click(Point(x, y), clickCount: 2);
      await Future.delayed(
          const Duration(milliseconds: 200)); // Espera processamento

      final selectedText =
          await page!.evaluate<String>('() => window.__getSelectedText()');
      expect(selectedText, equals('Hello'));
    });

    test('Double click on "a" selects only "a"', () async {
      final canvasBox = await page!.evaluate<Map>(
          '() => document.querySelector("canvas").getBoundingClientRect().toJSON()');
      // Ajuste para a posição de "a" em "Canvas" (aproximadamente offset 50-60)
      final x = (canvasBox['x'] as num) +
          56.7 +
          60; // Aproximadamente "a" em "Canvas"
      final y = (canvasBox['y'] as num) +
          30; // Linha 0, ajustada para altura aproximada
      await page!.mouse.click(Point(x, y), clickCount: 2);
      await Future.delayed(
          const Duration(milliseconds: 200)); // Espera processamento

      final selectedText =
          await page!.evaluate<String>('() => window.__getSelectedText()');
      expect(selectedText, equals('a'));
    });
  });
}
