import 'dart:io';

void main() {
  // Configurações do script
  final config = MergeConfig(
    // Lista de diretórios fonte para buscar arquivos
    sourceDirs: [
      r'C:\MyDartProjects\canvas_text_editor\lib',
      r'C:\MyDartProjects\canvas_text_editor\test',
    ],

    // Lista de diretórios a serem ignorados (caminhos relativos ou absolutos)
    ignoredDirs: [
      'build',
      'generated',
      '.dart_tool',
      'node_modules',
      r'C:\MyDartProjects\canvas_text_editor\.dart_tool',
      r'C:\MyDartProjects\canvas_text_editor\lib\old',
    ],

    // Lista de extensões de arquivos a serem mesclados
    fileExtensions: ['.dart'],

    // Arquivo de saída
    outputPath:
        r'C:\MyDartProjects\canvas_text_editor\scripts\codigo_mesclado.dart.txt',
  );

  mergeFiles(config);
}

class MergeConfig {
  final List<String> sourceDirs;
  final List<String> ignoredDirs;
  final List<String> fileExtensions;
  final String outputPath;

  MergeConfig({
    required this.sourceDirs,
    required this.ignoredDirs,
    required this.fileExtensions,
    required this.outputPath,
  });
}

void mergeFiles(MergeConfig config) {
  // Validar diretórios fonte
  for (final dirPath in config.sourceDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      print('Aviso: Diretório não encontrado: $dirPath');
    }
  }

  // Preparar arquivo de saída
  final outputFile = File(config.outputPath);
  if (outputFile.existsSync()) {
    outputFile.deleteSync();
    print('Arquivo de saída anterior removido.');
  }

  // Criar diretório de saída se não existir
  final outputDir = outputFile.parent;
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputSink = outputFile.openWrite(mode: FileMode.append);
  int totalFiles = 0;

  // Normalizar diretórios ignorados para comparação
  final normalizedIgnoredDirs =
      config.ignoredDirs.map((dir) => _normalizePath(dir)).toList();

  // Processar cada diretório fonte
  for (final sourceDirPath in config.sourceDirs) {
    final sourceDir = Directory(sourceDirPath);
    if (!sourceDir.existsSync()) continue;

    print('\nProcessando: $sourceDirPath');

    final files = sourceDir.listSync(recursive: true);

    for (final file in files) {
      if (file is File) {
        // Verificar se a extensão está na lista permitida
        final hasValidExtension = config.fileExtensions
            .any((ext) => file.path.toLowerCase().endsWith(ext.toLowerCase()));

        if (!hasValidExtension) continue;

        // Verificar se o arquivo está em um diretório ignorado
        if (_isInIgnoredDirectory(file.path, normalizedIgnoredDirs)) {
          continue;
        }

        try {
          final content = file.readAsStringSync();
          //outputSink.write('${'=' * 80}\n');
          outputSink.write('// Arquivo: ${file.path}\n');
          //outputSink.write('${'=' * 80}\n');
          outputSink.write(content);
          outputSink.write('\n\n');

          totalFiles++;
          print('  ✓ ${file.path}');
        } catch (e) {
          print('  ✗ Erro ao ler ${file.path}: $e');
        }
      }
    }
  }

  outputSink.close();

  print('\n${'=' * 80}');
  print('Mesclagem concluída!');
  print('Total de arquivos mesclados: $totalFiles');
  print('Extensões processadas: ${config.fileExtensions.join(', ')}');
  print('Arquivo de saída: ${config.outputPath}');
  print('=' * 80);
}

/// Normaliza um caminho para comparação
String _normalizePath(String path) {
  return path.replaceAll('\\', '/').toLowerCase().trim();
}

/// Verifica se um arquivo está dentro de um diretório ignorado
bool _isInIgnoredDirectory(String filePath, List<String> ignoredDirs) {
  final normalizedFilePath = _normalizePath(filePath);

  for (final ignoredDir in ignoredDirs) {
    // Verificar se é um caminho absoluto ou relativo
    if (ignoredDir.contains(':') || ignoredDir.startsWith('/')) {
      // Caminho absoluto
      if (normalizedFilePath.contains(ignoredDir)) {
        return true;
      }
    } else {
      // Nome de diretório relativo
      final pathSegments = normalizedFilePath.split('/');
      if (pathSegments.contains(ignoredDir)) {
        return true;
      }
    }
  }

  return false;
}
