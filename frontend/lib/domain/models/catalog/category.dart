import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// A browse category, such as a genre or mood.
@freezed
abstract class SpCategory with _$SpCategory {
  /// Creates a category.
  const factory SpCategory({
    required String id,
    required String name,
    required List<SpCategoryIcon> categoryIcons,
  }) = _SpCategory;

  /// Creates a category from the API's JSON, keeping its first icon.
  factory SpCategory.fromMap(Map<String, dynamic> map) {
    final icon = (map['icons'] as List).first as Map<String, dynamic>;
    return SpCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      categoryIcons: [
        SpCategoryIcon(
          url: icon['url'] as String,
          width: icon['width'] as int?,
          height: icon['height'] as int?,
        ),
      ],
    );
  }

  /// Creates categories from a JSON list.
  static List<SpCategory> fromMapList(List<dynamic> list) => [
    for (final map in list) SpCategory.fromMap(map as Map<String, dynamic>),
  ];
}

/// The icon image of a [SpCategory].
@freezed
abstract class SpCategoryIcon with _$SpCategoryIcon {
  /// Creates a category icon.
  const factory SpCategoryIcon({required String url, int? width, int? height}) =
      _SpCategoryIcon;
}
