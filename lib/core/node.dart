abstract class Node {
  final String nodeId;
  final String? parentId;

  Node({required this.nodeId, this.parentId});

  Map<String, dynamic> getAttributes();
  Node copyWith({
    String? nodeId,
    String? parentId,
  });
}
