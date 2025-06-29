class SpCategory {
  final String id;
  final String name;
  final List<SpCategoryIcon> categoryIcons;

  // Creata a spotify category from a Map
  factory SpCategory.fromMap(Map<String, dynamic> map) {
    return SpCategory(
      id: map["id"],
      name: map["name"],
      categoryIcons: [
        SpCategoryIcon(
          url: map["icons"][0]["url"],
          width: map["icons"][0]["width"],
          height: map["icons"][0]["height"],
        )
      ],
    );
  }

  // Convert a List of Maps to a List of Artist objects
  static List<SpCategory> fromMapList(List<dynamic> list) {
    return list
        .map((map) => SpCategory.fromMap(map as Map<String, dynamic>))
        .toList();
  }

  SpCategory(
      {required this.id, required this.name, required this.categoryIcons});
}

class SpCategoryIcon {
  final String url;
  final int? width;
  final int? height;

  SpCategoryIcon({required this.url, this.width, this.height});
}
