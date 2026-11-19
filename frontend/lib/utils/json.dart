/// Typed reads of nested JSON objects.
extension JsonMap on Map<String, dynamic> {
  /// The object at the end of [path], or `null` if any step is missing.
  Map<String, dynamic>? objectAt(List<String> path) {
    Object? value = this;
    for (final key in path) {
      if (value is! Map) return null;
      value = value[key];
    }
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  /// The list at the end of [path], or `null` if any step is missing.
  List<dynamic>? listAt(List<String> path) {
    final parent = path.length == 1
        ? this
        : objectAt(path.sublist(0, path.length - 1));
    final value = parent?[path.last];
    return value is List ? value : null;
  }
}
