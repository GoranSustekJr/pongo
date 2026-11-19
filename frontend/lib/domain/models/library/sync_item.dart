/// Which library item a sync item is: its kind, such as `favourite`, and its
/// key within the kind, such as the track ID.
typedef SyncKey = ({String kind, String key});

/// A library item as it's synced: its data, or `null` if there's no such
/// item, and when it last changed in milliseconds since the epoch, or 0 if
/// the item doesn't record that itself.
typedef SyncItem = ({Map<String, Object?>? data, int changedAt});

/// What was last synced of an item: a hash of its data, `null` once deleted,
/// when it changed, and whether the server still has to get the change.
typedef SyncState = ({String? hash, int changedAt, bool dirty});

/// Part of the library that's synced, such as the database or the settings.
abstract interface class SyncSource {
  /// The kinds of items this source holds.
  Set<String> get kinds;

  /// Every item this source holds.
  Future<Map<SyncKey, SyncItem>> snapshot();

  /// The item [key] as it's stored now.
  Future<SyncItem> item(SyncKey key);

  /// Stores [data] as item [key], or deletes the item if [data] is `null`.
  Future<void> apply(SyncKey key, Map<String, Object?>? data);
}

/// Where syncing keeps what it last synced.
abstract interface class SyncStateStore {
  /// Where the last sync left off on the server, or `null` before the first.
  Future<int?> cursor();

  /// Stores [cursor].
  Future<void> setCursor(int cursor);

  /// What was last synced of every item.
  Future<Map<SyncKey, SyncState>> states();

  /// Stores [states], replacing earlier ones.
  Future<void> saveStates(Map<SyncKey, SyncState> states);

  /// Forgets what was synced, as before the first sync.
  Future<void> clear();

  /// A count that grows with every change to the library, so a change since
  /// an earlier count shows.
  Future<int> changeCount();
}
