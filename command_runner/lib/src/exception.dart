class ArgumentException extends FormatException {
  final String? command;

  /// The name of the argument that was being parsed whent he error was discovered.
  final String? argumentName;

  ArgumentException(
    super.message, [
    this.command,
    this.argumentName,
    super.source,
    super.offset,
  ]);

  @override
  String toString() {
    return 'ArgumentException: $message';
  }
}
