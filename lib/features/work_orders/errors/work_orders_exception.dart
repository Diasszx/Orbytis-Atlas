final class WorkOrdersException implements Exception {
  const WorkOrdersException(this.message);

  final String message;

  @override
  String toString() => message;
}
