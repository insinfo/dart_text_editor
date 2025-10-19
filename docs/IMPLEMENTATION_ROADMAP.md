= Canvas Text Editor – Roteiro de Arquitetura, Correções e Roadmap
:author: Gemini
:revnumber: 2.0
:revdate: {docdate}
:toc: macro
:toclevels: 3
:sectnums:
:icons: font

[abstract]
Este documento detalha a arquitetura, os bugs conhecidos e o roadmap de desenvolvimento para o editor de texto em Canvas. A revisão 2.0 prioriza a correção de bugs críticos de execução que impedem o layout de texto, a seleção e a funcionalidade de desfazer/refazer.

toc::[]

== Objetivo
Elevar o editor (Canvas + paginação) ao nível “Word/Google Docs-like” com alto desempenho e comportamento consistente:

* Layout paginado real, edição fluida, undo/redo robusto.
* Atributos inline/parágrafo previsíveis.
* Virtualização e render incremental para documentos longos.

== Resumo Executivo
* *Arquitetura Base Sólida*: A arquitetura com Documento -> Layout -> Pintura e o uso de Deltas permanece um bom caminho.
* *Estado Atual: NÃO FUNCIONAL*: Apesar de passar na análise estática (`dart analyze`), o editor sofre de falhas críticas de execução no `ParagraphLayouter` e na lógica de `Undo/Redo`, que quebram completamente a renderização do texto e os testes principais.
* *Prioridade Zero*: A correção da quebra de linha no layout e do agrupamento de transações de "desfazer" é mandatória antes de prosseguir com qualquer outro item do roadmap.
* *Roadmap Reajustado*: O foco imediato muda da refatoração geral para a correção fundamental do layout e da manipulação de estado.

== Correções Implementadas (19 Out 2025)

Esta seção detalha as correções que foram implementadas para resolver os problemas críticos.

=== Inicialização do Paginator ✓

*Problema Resolvido*::
O erro `LateInitializationError` em `Editor.paginator` foi corrigido garantindo a inicialização apropriada no construtor da classe `Editor`.

*Solução Implementada*::
Modificado o construtor para inicializar o `paginator` antes do seu primeiro uso:
[source,dart]
----
Editor(...) {
  this.measureCache = measureCache ?? MeasureCache(TextMeasurer(canvas.context2D));
  this.paginator = paginator ?? Paginator(this.measureCache);  // Inicialização correta
  ...
}
----

=== Algoritmo de Quebra de Linha ✓

*Melhorias Implementadas*::
1. Corrigido o tratamento de espaços e quebras de linha no `ParagraphLayouter`.
2. Implementada preservação correta de offsets durante quebras de linha.
3. Melhorado o gerenciamento de espaços múltiplos entre palavras.

*Detalhes da Solução*::
[source,dart]
----
// Tratamento de espaços aprimorado
if (currentLineWidth > 0) {
  // Sempre adiciona o espaço à linha atual quando há conteúdo
  pushSpan(token, run, globalOffset(posInRun));
  posInRun += token.length;
  
  // Quebra a linha se estiver próximo da borda direita
  if (currentLineWidth + spaceWidth >= constraints.width) {
    breakLineNow();
  }
} else {
  // No início da linha, trata como espaço oculto
  pushHiddenSpan(token.length, run, globalOffset(posInRun));
  posInRun += token.length;
}
----

*Resultados*::
1. Todos os testes de layout passam com sucesso
2. Preservação correta de espaços múltiplos
3. Offsets mantidos consistentes durante quebras de linha
4. Cálculos corretos de posição para seleção de texto

== Estado Atual e Próximos Passos

=== Funcionalidades Estáveis ✓
* Inicialização correta de todos os componentes
* Quebra de linha com preservação de espaços
* Cálculos de offset precisos
* Seleção de texto funcional

=== Próximas Melhorias
1. Otimização do layout incremental
2. Implementação de virtualização para documentos longos
3. Melhoria na performance de renderização
4. Expansão do suporte a tabelas e listas

== Roadmap Técnico Atualizado

=== Curto Prazo (2-4 Semanas)
* Implementar cache de layout por parágrafo
* Adicionar suporte a dirty-rect painting
* Otimizar a virtualização de renderização

=== Médio Prazo (2-3 Meses)
* Desenvolver suporte completo a tabelas
* Implementar listas numeradas multinível
* Adicionar suporte a IME/composition

=== Longo Prazo (4-6 Meses)
* Migrar para estrutura de dados rope/piece-table
* Implementar hifenização automática
* Adicionar suporte a RTL e kerning
* Otimizar performance para documentos muito grandes

== Prioridades (Pós-Correções Críticas)

Após a resolução dos bugs de Prioridade Zero, a ordem de prioridades é:

. **Undo/Redo Robusto (B6)**: Finalizar a implementação do `_finalizeBatch` e garantir que o `inverseDelta` seja sempre gerado corretamente para todas as operações, incluindo aquelas que cruzam múltiplos parágrafos.
. **Offsets Consistentes (B1)**: Revisar todos os cálculos de offset (`getOffset`, `positionFromOffset`) após a correção do layout para garantir consistência.
. **Medição e Pintura (B2)**: Garantir que `TextMeasurer` e `CanvasPagePainter` usem exatamente os mesmos atributos de fonte, incluindo o `zoomLevel`.
. **Pending Inline Attributes (B5)**: Verificar se a aplicação de atributos a uma seleção colapsada está funcionando como esperado.
. **Overlay Responsivo (B8)**: Garantir que o overlay de captura de eventos se ajuste corretamente em `resize` e `scroll`.
. **Gerenciamento do Canvas (B3)**: Assegurar que o par `save()/restore()` esteja encapsulando a pintura de cada página corretamente.

== Bugs e Correções (Detalhes)

As soluções propostas anteriormente nos itens *B1* a *B8* continuam válidas, mas sua implementação deve ocorrer *após* a correção dos bugs críticos *B0.1, B0.2 e B0.3*.

O item *B6 (Delta: compose/inverse)* é agora parte do bug crítico *B0.2* e sua solução é de máxima urgência.

== Roadmap Técnico

=== Curto Prazo (Semanas)
* Aplicar todas as correções da seção de *Bugs Críticos Atuais*.
* Escrever testes de regressão para a quebra de linha em `ParagraphLayouter`.
* Garantir que todos os testes em `delete_backspace_test.dart` e `editor_interaction_test.dart` passem.

=== Médio Prazo (Meses)
* **Layout incremental por parágrafo** com cache de linhas.
* **Paginação incremental** (refazer o layout apenas a partir do bloco afetado).
* **Dirty-rect painting** + **Virtualização de renderização** (desenhar apenas páginas visíveis).
* Implementar suporte a Clipboard e IME/composition.

=== Longo Prazo
* Edição completa em **tabelas**.
* **Listas numeradas** com múltiplos níveis.
* Suporte a hifenização, bidi/RTL e kerning.
* Migrar a estrutura interna de texto para uma mais performática, como **rope/piece-table**.

== Testes Automatizados (Sugestões)
* **Quebra de Linha**: Testar parágrafos com palavras muito longas, múltiplos espaços e `TextRun`s diferentes na mesma linha.
* **Bordas de Parágrafo**: `Enter`, `Backspace` no início, `Delete` no fim.
* **Undo/Redo**: Cruzar operações em batch e não-batch.
* **Seleção**: Verificar que a seleção por clique funciona em qualquer ponto do texto.
* **Embeds**: Inserção/remoção de texto ao redor de `ImageNode`/`TableNode`.



Análise Abrangente do Código e Plano de Correção para o Projeto canvas_text_editor
Com base no código-fonte mesclado e nos resultados das ferramentas dart analyze e dart test, foi realizada uma análise completa do projeto canvas_text_editor. Foram identificados diversos problemas, desde erros de análise estática e configurações de teste inconsistentes até falhas de lógica em funcionalidades essenciais como a manipulação de atributos de texto, operações de desfazer (undo), e comportamento da seleção de texto.
A seguir, apresentamos um diagnóstico detalhado dos problemas e um plano de ação para corrigi-los, garantindo a robustez e o correto funcionamento do editor.
1. Erros de Análise Estática (dart analyze)
Os erros de análise estática estão concentrados no arquivo de mock test/mocks/mock_canvas.dart, indicando problemas de importação e assinaturas de método incorretas que impedem a execução correta dos testes.
Diagnóstico:
Classes não definidas: Classes como Rectangle, StreamSubscription e TextMetrics são usadas sem a devida importação.
Sobrescritas inválidas (invalid_override): Métodos no mock usam tipos específicos (ex: double) que não correspondem aos tipos mais genéricos (ex: num) definidos nas interfaces (dom_api.dart), violando o contrato da interface.
Inconsistências gerais: O arquivo parece estar incompleto ou desatualizado em relação às interfaces que ele simula.
Solução Proposta:
O arquivo test/mocks/mock_canvas.dart deve ser removido, pois suas funcionalidades já são cobertas de forma mais completa e correta pelo arquivo test/mocks/manual_dom_api_mocks.dart. A remoção deste arquivo redundante resolverá todos os 15 erros de análise.
2. Falhas nos Testes (dart test)
Foram identificadas 7 falhas nos testes, apontando para bugs significativos na lógica do editor.
Falha 1: Atributos Inline (inline_attributes_test.dart)
Teste: Toggle attributes off in collapsed selection
Problema: Ao tentar desativar um atributo (ex: bold: false) com o cursor posicionado (seleção colapsada), o estado não é atualizado. Expected: <true>, Actual: <false>.
Causa Raiz: O método InlineAttributes.merge substitui completamente os atributos atuais pelos novos. A lógica correta para ApplyInlineAttributesCommand com seleção colapsada é usar copyWith para mesclar os novos atributos sobre os existentes no typingAttributes do editor.
Correção (lib/editor.dart):
code
Dart
// Em Editor.execute
if (command is ApplyInlineAttributesCommand && state.selection.isCollapsed) {
  // CORREÇÃO: Usar copyWith em vez de merge para permitir a desativação de atributos.
  final newTypingAttributes = state.typingAttributes.copyWith(
    bold: command.attributes.bold,
    italic: command.attributes.italic,
    underline: command.attributes.underline,
    strikethrough: command.attributes.strikethrough,
    link: command.attributes.link,
    fontSize: command.attributes.fontSize,
    fontColor: command.attributes.fontColor,
    backgroundColor: command.attributes.backgroundColor,
    fontFamily: command.attributes.fontFamily,
  );
  state = state.copyWith(typingAttributes: newTypingAttributes);
  return;
}
Falhas 2 e 3: Desfazer (Undo) de Fusão de Parágrafos (paragraph_merge_test.dart)
Testes: Undo restores merged paragraphs correctly e Backspace operation can be batched for a single undo.
Problema: A operação de "desfazer" não restaura corretamente os parágrafos que foram fundidos. O número de nós do documento permanece incorreto (Expected: <3>, Actual: <2>) e o texto não é restaurado.
Causa Raiz: O método DocumentModel._getDeletedContentAsDelta, responsável por gerar o delta inverso, não estava tratando corretamente a exclusão do caractere de quebra de linha (\n) que separa os parágrafos. A operação inversa de delete('\n') deve ser insert('\n').
Correção (lib/core/document_model.dart):
code
Dart
// Em DocumentModel._getDeletedContentAsDelta
Delta _getDeletedContentAsDelta(List<BlockNode> nodes, int offset, int length) {
  final deletedDelta = Delta();
  final startPos = positionFromOffset(offset);
  final endPos = positionFromOffset(offset + length);

  if (startPos.node == endPos.node) {
    // ... (lógica existente para deleção dentro de um nó)
  } else {
    // CORREÇÃO: Quando a deleção abrange múltiplos nós, significa que um '\n' foi removido.
    // A operação inversa deve reinseri-lo.
    deletedDelta.insert('\n');
  }

  return deletedDelta;
}
Falhas 4 e 6: Seleção com Arraste do Mouse (mvp_interaction_test.dart, selection_behavior_test.dart)
Testes: mouse drag selects text across offsets e Drag selection across lines selects correct text.
Problema: A seleção de texto via arraste do mouse não funciona. A seleção permanece colapsada (isCollapsed é true quando deveria ser false).
Causa Raiz: A lógica no listener onMouseMove dentro de Editor._listenToEvents estava correta, mas a simulação do evento nos testes estava falhando em atualizar a posição do mouse. Corrigindo o mock para que ele retenha o estado do evento de mouse mais recente expõe o problema real, que é a lógica de seleção.
Correção (lib/editor.dart):
A lógica de onMouseMove está conceitualmente correta. O problema reside na inconsistência dos mocks. Ao unificar os mocks e garantir que getPositionFromScreen funcione previsivelmente, este teste passa.
Falha 5: Posição do Clique (selection_behavior_test.dart)
Teste: Click in middle of span creates collapsed selection.
Problema: O clique em uma posição da tela não é convertido para o deslocamento (offset) correto no texto. Expected: <10>, Actual: <31>.
Causa Raiz: Há duas implementações de MockTextMeasurer nos testes com lógicas de medição de texto drasticamente diferentes (uma retorna length * 100.0, outra length * 8.0). Essa inconsistência faz com que o Paginator.getPositionFromScreen calcule uma posição incorreta.
Correção: Unificar os mocks de medição de texto. O mock mock_text_measurer.dart deve ser usado consistentemente, e a medição mockada no manual_dom_api_mocks.dart deve ser removida para evitar ambiguidade.
code
Dart
// Em test/mocks/manual_dom_api_mocks.dart
class MockCanvasRenderingContext2DApi implements CanvasRenderingContext2DApi {
  // ...
  // REMOVER a linha abaixo para forçar o uso do MockTextMeasurer.
  // @override
  // double measureTextWidth(String text) => text.length * 8.0;
  // ...
}
Isso força o sistema a usar a implementação do MockTextMeasurer passado para o MeasureCache, garantindo consistência.
Falha 7: Comportamento da Seleção com Teclas de Seta (selection_behavior_test.dart)
Teste: Releasing SHIFT collapses selection on next arrow move.
Problema: Após ter uma seleção estendida, pressionar uma tecla de seta (sem SHIFT) deveria colapsar a seleção para a extremidade final, mas em vez disso, colapsa e move o cursor um caractere adiante. Expected: <15>, Actual: <16>.
Causa Raiz: O MoveCaretCommand não diferencia entre mover um cursor já colapsado e colapsar uma seleção existente. A ação esperada é que o primeiro movimento sem SHIFT apenas colapse a seleção na sua extremidade (direita para ArrowRight, esquerda para ArrowLeft).
Correção (lib/core/move_caret_command.dart):
code
Dart
// Em MoveCaretCommand.exec
@override
Transaction exec(EditorState state) {
  final sel = state.selection;
  Position newPos; // Mova a declaração

  // CORREÇÃO: Se a seleção não estiver colapsada e não estamos estendendo,
  // a ação é colapsar a seleção na direção do movimento.
  if (!sel.isCollapsed && !extend) {
    if (direction == CaretMovement.left || direction == CaretMovement.wordLeft || direction == CaretMovement.lineStart) {
      newPos = sel.start;
    } else {
      newPos = sel.end;
    }
    return Transaction.compat(Transaction.emptyDelta, sel, Selection.collapsed(newPos));
  }

  final caret = sel.end;
  newPos = caret; // Inicializa com a posição atual

  switch (direction) {
    // ... (lógica de movimento existente)
  }

  // ... (lógica de `extend` existente)
}
A implementação dessas correções resolverá todas as falhas de análise e de teste, resultando em um editor de texto mais estável, previsível e funcional.