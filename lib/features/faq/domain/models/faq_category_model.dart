class FaqCategoryModel {
  final String id;
  final String name;

  FaqCategoryModel({
    required this.id,
    required this.name,
  });

  factory FaqCategoryModel.fromJson(Map<String, dynamic> json) {
    return FaqCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không xác định',
    );
  }
}
