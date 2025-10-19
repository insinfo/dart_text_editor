= Canvas Text Editor – Roteiro de Arquitetura, Correções e Roadmap
:author: Gemini
:revnumber: 2.0
:revdate: {docdate}
:toc: macro
:toclevels: 3
:sectnums:
:icons: font

[abstract]
Este documento detalha a arquitetura, os bugs conhecidos e o roadmap de desenvolvimento para o editor de texto em Canvas. 
A revisão 2.0 prioriza a correção de bugs críticos de execução que impedem o layout de texto, a seleção e a funcionalidade de desfazer/refazer.

toc::[]

== Objetivo
Elevar o editor (Canvas + paginação) ao nível “Word/Google Docs-like” com alto desempenho e comportamento consistente:

* Layout paginado real, edição fluida, undo/redo robusto.
* Atributos inline/parágrafo previsíveis.
* Virtualização e render incremental para documentos longos.

== Resumo Executivo
* *Arquitetura Base Sólida*: A arquitetura com Documento -> Layout -> Pintura e o uso de Deltas permanece um bom caminho.
* *Estado Atual: NÃO FUNCIONAL*: Apesar de passar na análise estática (`dart analyze`), 
o editor sofre de falhas críticas de execução no `ParagraphLayouter` e na lógica de `Undo/Redo`, que quebram completamente a renderização do texto e os testes principais.
* *Prioridade Zero*: A correção da quebra de linha no layout e do agrupamento de transações de "desfazer" é mandatória antes de prosseguir com qualquer outro item do roadmap.
* *Roadmap Reajustado*: O foco imediato muda da refatoração geral para a correção fundamental do layout e da manipulação de estado.


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
* (Não planejado) Adicionar suporte a RTL 
* dicionar suporte a kerning
* Otimizar performance para documentos muito grandes

== Prioridades (Pós-Correções Críticas)

Após a resolução dos bugs de Prioridade Zero, a ordem de prioridades é:

. **Undo/Redo Robusto (B6)**: Finalizar a implementação do `_finalizeBatch` e garantir que o `inverseDelta` seja sempre gerado corretamente para todas as operações, incluindo aquelas que cruzam múltiplos parágrafos.
. **Offsets Consistentes (B1)**: Revisar todos os cálculos de offset (`getOffset`, `positionFromOffset`) após a correção do layout para garantir consistência.
. **Medição e Pintura (B2)**: Garantir que `TextMeasurer` e `CanvasPagePainter` usem exatamente os mesmos atributos de fonte, incluindo o `zoomLevel`.
. **Pending Inline Attributes (B5)**: Verificar se a aplicação de atributos a uma seleção colapsada está funcionando como esperado.
. **Overlay Responsivo (B8)**: Garantir que o overlay de captura de eventos se ajuste corretamente em `resize` e `scroll`.
. **Gerenciamento do Canvas (B3)**: Assegurar que o par `save()/restore()` esteja encapsulando a pintura de cada página corretamente.



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

