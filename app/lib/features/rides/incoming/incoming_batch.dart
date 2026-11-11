/// Ride files another app sent us, already copied into the phone's storage.
class IncomingBatch {
  const IncomingBatch({
    this.added = 0,
    this.alreadyHere = 0,
    this.rejected = const [],
  });

  /// New rides, waiting for the upload queue.
  final int added;

  /// Files whose content is already on the phone.
  final int alreadyHere;

  /// The names of the files that were not ride files, or could not be opened.
  final List<String> rejected;

  bool get isEmpty => added == 0 && alreadyHere == 0 && rejected.isEmpty;

  static IncomingBatch? fromMap(Object? value) {
    if (value is! Map) return null;
    return IncomingBatch(
      added: _int(value['added']),
      alreadyHere: _int(value['alreadyHere']),
      rejected: [
        for (final name in value['rejected'] as List? ?? const [])
          if (name is String && name.isNotEmpty) name,
      ],
    );
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;
}
