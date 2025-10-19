= Roteiro de Implementação Consolidado: Canvas Text Editor

:toc: left
:toclevels: 3
:sectnums:

> **Princípios operacionais:**
>
> *   Este documento deve ser **mantido atualizado** conforme o código evolui.
> *   Nunca adicione dependecias no projeto que dependa de codegen
> *   Validar sempre com: `dart analyze`, `dart test` e `webdev build`.
> *  usar o comando dart run build_runner build --delete-conflicting-outputs e webdev build para ver se esta compilando sempre
> *   Priorizar TDD: testes unitários para o núcleo (modelo/delta), layout (paginação) e interação (seleção/comandos).

== 1. Contexto e Referências

Tabela de referência de editores de texto/código em Canvas (open source):

|===
| Projeto | Link | Descrição (super curta) | Paginado | PDF

| ONLYOFFICE DocumentServer
| https://github.com/ONLYOFFICE/DocumentServer
| Editor tipo Word em Canvas, completo e colaborativo
| ✅
| ✅

| canvas-editor (Hufe921)
| https://github.com/Hufe921/canvas-editor
| WYSIWYG em Canvas/SVG com páginas, margens, cabeç./rodapé
| ✅
| ✅

| Carota
| https://github.com/danielearwicker/carota
| Rich text em Canvas, minimalista e antigo
| ❌
| ❌*

| RichTextJS
| https://github.com/markusmoenig/RichTextJS
| Protótipo de rich text em Canvas, recursos básicos
| ❌
| ❌

| Mozilla Bespin (arquivado)
| https://github.com/mozilla/bespinserver
| Editor de **código** via Canvas, histórico
| ❌
| ❌

| Canvas Text Editor (tutorial)
| https://github.com/grassator/canvas-text-editor-tutorial
| Texto **plano** em Canvas (didático)
| ❌
| ❌
|===
_(*) No Carota é possível exportar indiretamente convertendo o canvas em imagem/PDF._

Análise do Código-Fonte
1. O que foi Implementado (Pontos Fortes da Arquitetura)
O projeto possui uma base arquitetônica sólida e bem projetada, com várias funcionalidades essenciais já implementadas e funcionais:
Modelo de Dados Robusto (core/): A estrutura com DocumentModel, BlockNode (e suas especializações como ParagraphNode, ImageNode, ListNode, TableNode) e TextRun é flexível e extensível. A utilização de atributos separados (InlineAttributes, ParagraphAttributes) é uma excelente prática.
Engine de Deltas e Transações: O sistema de Delta para representar alterações é eficiente. O uso de Transaction, que agrupa um Delta, seu inverso (inverseDelta) e o estado da seleção antes e depois, é fundamental para um sistema de Undo/Redo confiável.
Padrão de Comando (core/editor_command.dart): A abstração de todas as ações de edição em classes de EditorCommand (InsertTextCommand, DeleteCommand, etc.) desacopla a lógica de manipulação do estado da interface do usuário, facilitando testes e manutenção.
Layout e Paginação (layout/): O Paginator já consegue dividir o documento em páginas (PageLayout) e o ParagraphLayouter realiza a quebra de linhas, considerando diferentes atributos de texto. A inclusão de LayoutSpan com offsets absolutos foi um passo crucial para a precisão da seleção.
Renderização Precisa (render/): O CanvasPagePainter implementa corretamente o recorte (clip) do conteúdo aos limites da página, evitando "vazamentos" visuais. A pintura da seleção agora é precisa, colorindo apenas o trecho de texto selecionado em um span, e não a linha inteira.
Interação do Usuário (editor.dart): O editor já captura eventos de teclado e mouse, permitindo:
Digitação, Backspace e Delete.
Navegação por setas, Ctrl+setas (palavra) e Home/End (linha).
Seleção por arrasto do mouse e extensão com Shift+Setas.
Seleção de tudo (Ctrl+A).
Batching de Comandos: A lógica para agrupar múltiplos BackspaceCommand ou DeleteCommand contínuos em uma única transação de undo/redo está implementada, melhorando a experiência do usuário.
Abstração do DOM (util/dom_api.dart): A criação de uma camada de abstração para as APIs do DOM (dart:html) é o ponto mais forte da arquitetura, pois permite que todo o núcleo do editor seja testado de forma unitária, sem depender de um ambiente de navegador.
2. Bugs e Problemas Identificados no Código
🐞 Batching de Undo para Digitação: Embora o código em editor.dart chame _startBatch para InsertTextCommand, o roteiro indica que isso não está funcionando como esperado. Cada caractere digitado ainda cria uma transação de undo separada. A lógica de batch precisa ser revisada para garantir que as inserções de texto contínuas sejam agrupadas corretamente.
🐞 Suporte Incompleto a Blocos Não-Texto: O DocumentModel suporta ImageNode, ListNode e TableNode, mas o Paginator e o CanvasPagePainter apenas renderizam placeholders (espaços reservados) para eles. Mais importante, os comandos de edição (InsertTextCommand, DeleteCommand, etc.) não funcionam dentro ou ao redor desses blocos, pois sua lógica é focada em encontrar _RunLocation dentro de ParagraphNode.
🐞 Navegação Vertical Instável: O roteiro aponta que a posição horizontal do cursor não é preservada ao navegar para cima/baixo. O código em MoveCaretCommand contém a lógica para _desiredX, que deveria resolver isso. O fato de ainda ser um problema sugere um bug sutil, possivelmente na forma como paginator.getPositionFromScreen interpreta a coordenada x desejada em linhas de comprimentos diferentes.
🐞 Alinhamento Justificado Não Funcional: A classe ParagraphLayouter possui um método _applyJustifyAlignment, mas sua lógica de adicionar espaços extras é uma simplificação que não produz um resultado visualmente justificado. A distribuição de espaço precisa ser calculada e aplicada de forma mais sofisticada durante a medição e o desenho.
Erros de Análise e Teste: Conforme o roteiro aponta, há erros que impedem a compilação limpa e a execução de testes.
Nos testes (delete_backspace_test.dart), a instanciação de DocumentModel está incorreta (DocumentModel(...) em vez de DocumentModel([...])).
Os mocks de teste precisam ser atualizados para implementar as interfaces da dom_api.dart (implements CanvasElementApi), garantindo a segurança de tipos.
3. O que Falta Implementar
Layout e Renderização de Blocos: Implementação completa da lógica de layout e renderização para Imagens, Listas (com marcadores e indentação) e Tabelas (com cálculo de colunas/linhas e bordas).
Interação Avançada:
Seleção por duplo clique (palavra) e triplo clique (parágrafo).
Comandos e interface para aplicar formatações (negrito, itálico, tamanho da fonte, etc.) na seleção atual.
Navegação e edição dentro de estruturas complexas, como células de tabelas.
Otimização de Performance:
Virtualização: O Editor._doPaint atualmente renderiza todas as páginas. É necessário integrar a VirtualizationStrategy para renderizar apenas as páginas visíveis na tela.
Cache de Rasterização: A classe RasterCache existe, mas não está sendo usada. A sua implementação é crucial para armazenar páginas pré-renderizadas como imagens, tornando a rolagem (scroll) fluida.
Funcionalidades Adicionais:
Exportação para PDF: A classe PdfExporter está vazia.
Controle de Viúvas e Órfãs: A classe WidowOrphanControl existe, mas sua lógica não é aplicada no Paginator para evitar linhas de parágrafo isoladas entre páginas.
Cobertura de Testes: A suíte de testes precisa ser expandida para cobrir os cenários descritos no roteiro, especialmente os casos de seleção complexa, merges de parágrafo e o funcionamento correto dos novos tipos de blocos.
Roteiro de Implementação Atualizado
A seguir, uma versão revisada e atualizada do roteiro, refletindo a análise do código.
Roteiro de Implementação Consolidado: Editor de Texto em Canvas
Princípios operacionais:
Este documento deve ser mantido atualizado conforme o código evolui.
Nunca adicione dependências no projeto que dependam de build_runner (codegen) para manter o ambiente de desenvolvimento simples e evitar conflitos de build.
Validar sempre com: dart analyze, dart test e webdev build.
Priorizar TDD: testes unitários para o núcleo (modelo/delta), layout (paginação) e interação (seleção/comandos).
1. Status Atual (O que foi feito) ✅
O projeto já possui uma base sólida e funcional, com as seguintes funcionalidades implementadas e estabilizadas:
✅ Estrutura do Documento: Modelo de dados robusto com DocumentModel, BlockNode, ParagraphNode e TextRun.
✅ Engine de Deltas: Sistema para aplicar e reverter alterações no documento de forma eficiente e transacional.
✅ Sistema de Comandos: Padrão de comando desacoplado (EditorCommand) para todas as ações de edição.
✅ Sistema de Undo/Redo: Pilhas de undo e redo funcionais.
✅ Batching de Comandos (Deleção): Agrupamento de Backspace e Delete contínuos em uma única transação de undo.
✅ Layout de Parágrafos: ParagraphLayouter calcula a quebra de linhas e a posição do texto.
✅ Paginação: Paginator divide o documento em páginas, calculando a origem (yOrigin) de cada página corretamente.
✅ Renderização Precisa:
Pintura de Seleção: O fundo da seleção é desenhado apenas no trecho exato do texto.
Clip de Página: O conteúdo é recortado (clip) para não "vazar" para fora da área útil da página.
✅ Navegação e Seleção:
Cursor: Movimentação via setas, Ctrl+setas (palavra) e Home/End (linha).
Mouse: Seleção por arrasto.
Teclado: Extensão de seleção com Shift + Setas e seleção total com Ctrl+A.
✅ Abstração do DOM: A API em dom_api.dart desacopla o código do dart:html, permitindo testes unitários eficazes.
2. Correções Imediatas e Bugs Críticos 🐞
Esta seção aborda os erros que impedem o funcionamento, a compilação e a boa experiência de uso.
Bug Lógico: Batching de Undo para Digitação
Problema: O agrupamento de transações não funciona para InsertTextCommand. Cada caractere digitado gera uma entrada separada no histórico.
Solução: [ ] Revisar a lógica em Editor.execute e _startBatch para garantir que InsertTextCommand contínuos sejam efetivamente agrupados em uma única transação, finalizada após uma pausa na digitação.
Bug de Navegação: Navegação Vertical Instável
Problema: Ao mover o cursor para cima ou para baixo, a posição horizontal (coluna) não é preservada de forma consistente.
Solução: [ ] Depurar a interação entre MoveCaretCommand e Paginator.getPositionFromScreen. A variável _desiredX já existe, mas pode não estar sendo usada ou calculada corretamente em todos os cenários (ex: linhas com fontes ou tamanhos diferentes).
Bug de Layout: Alinhamento Justificado Não Implementado
Problema: A opção de justificar parágrafos não tem efeito visual correto.
Solução: [ ] Reescrever o método _applyJustifyAlignment em ParagraphLayouter. Em vez de adicionar caracteres de espaço, a solução correta é calcular o espaço extra na linha e distribuí-lo durante a renderização, aumentando o espaçamento entre as palavras existentes.
Qualidade de Código e Testes:
Problema: O analisador reporta múltiplos avisos (warning) e os testes estão quebrados ou desatualizados.
Solução:
[ ] Realizar uma passagem de "limpeza" no código, corrigindo todos os avisos reportados pelo dart analyze.
[ ] Corrigir os testes quebrados em delete_backspace_test.dart, ajustando a instanciação de DocumentModel e garantindo que os mocks implementem as interfaces da dom_api.
3. Próximos Passos: Melhorias e Novas Funcionalidades 🚀
Funcionalidade Central: Suporte a Blocos de Conteúdo
[ ] Imagens: Desenvolver a lógica de layout e renderização para ImageNode. Permitir redimensionamento básico.
[ ] Listas (Ordenadas e Não Ordenadas): Implementar o layout para ListNode, incluindo indentação, marcadores (bullets/números) e renderização.
[ ] Tabelas: Implementar o layout para TableNode, incluindo o cálculo de largura de colunas, altura de linhas e renderização de bordas. A edição dentro de células será um desafio subsequente.
Interação do Usuário (UX)
[ ] Seleção Avançada: Implementar seleção por duplo-clique (palavra) e triplo-clique (parágrafo).
[ ] Comandos de Formatação: Criar e integrar comandos para alterar atributos de texto (bold, italic, fontSize, etc.) na seleção atual, com atalhos de teclado (ex: Ctrl+B).
[ ] Navegação Estruturada: Implementar a movimentação do cursor entre células de tabelas e itens de listas.
Otimização de Performance
[ ] Virtualização de Renderização: Integrar VirtualizationStrategy ao Editor._doPaint para renderizar apenas as páginas visíveis, evitando processamento desnecessário para documentos longos.
[ ] Cache de Rasterização (RasterCache): Ativar o RasterCache para armazenar páginas já renderizadas como imagens, garantindo que a rolagem (scroll) seja perfeitamente fluida.
Features Adicionais
[ ] Exportação para PDF: Implementar a lógica da classe PdfExporter.
[ ] Controle de Viúvas e Órfãs: Implementar a lógica em Paginator para evitar que linhas de parágrafo fiquem isoladas no início ou fim de uma página.
4. Testes Pendentes 🧪
[ ] Ativar e Completar a Suíte de Testes: Corrigir todos os testes existentes para que passem.
[ ] Criar Novos Testes para:
Seleção cruzando múltiplos parágrafos e páginas.
Batching de inserção de texto.
Renderização e seleção em imagens e tabelas (quando implementadas).
Hit-test (clique do mouse) cruzando o yOrigin de páginas.
Merges de parágrafo em cenários complexos (ex: com estilos diferentes).
Verificação de que a navegação vertical mantém a coluna (_desiredX).
5. Roteiro Sugerido (Ordem de Execução)
Estabilização (Base Sólida):
Corrija os erros de dart analyze e os testes quebrados.
Implemente as correções da seção 2 (batching de digitação, navegação vertical, justificado).
Funcionalidade Essencial (Blocos):
Foque em implementar o suporte completo para Listas, depois Imagens e, por fim, Tabelas (layout e renderização primeiro, edição depois).
Melhoria de Interação (UX):
Adicione a seleção avançada (duplo/triplo clique) e os comandos de formatação.
Otimização de Performance (Fluidez):
Implemente a virtualização da renderização e o cache de rasterização. Esta etapa é crucial para que o editor seja de "alto desempenho".
Funcionalidades Finais (Polimento):
Implemente features como exportação para PDF e controle de viúvas/órfãs.
Continue expandindo a cobertura de testes em paralelo com cada nova funcionalidade.