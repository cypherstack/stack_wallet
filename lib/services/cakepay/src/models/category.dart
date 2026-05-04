class CakePayCategory {
  final int id;
  final String name;
  final String? emoji;
  final String? slug;
  final bool isActive;
  final int sortOrder;

  CakePayCategory({
    required this.id,
    required this.name,
    this.emoji,
    this.slug,
    required this.isActive,
    required this.sortOrder,
  });

  factory CakePayCategory.fromJson(Map<String, dynamic> json) {
    return CakePayCategory(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? '') as String,
      emoji: json['emoji'] as String?,
      slug: json['slug'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'CakePayCategory($id, $name)';
}
