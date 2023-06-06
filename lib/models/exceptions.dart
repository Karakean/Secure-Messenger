class FileRefusedException implements Exception {
  final String message;

  FileRefusedException(this.message);

  @override
  String toString() => 'FileRefusedException: $message';
}