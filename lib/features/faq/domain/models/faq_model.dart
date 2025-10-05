class FaqModel {
  final String id;
  final String name;
  final String? answer;
  final String? categoryId;
  final String? dateCreation;
  final String? dateMod;

  FaqModel({
    required this.id,
    required this.name,
    this.answer,
    this.categoryId,
    this.dateCreation,
    this.dateMod,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không có tiêu đề',
      answer: json['answer']?.toString(),
      categoryId: json['knowbaseitemcategories_id']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMod: json['date_mod']?.toString(),
    );
  }
}
