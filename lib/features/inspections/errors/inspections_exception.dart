final class InspectionsException implements Exception {
  const InspectionsException(this.message);

  final String message;

  @override
  String toString() => message;
}
