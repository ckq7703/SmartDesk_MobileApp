class SolutionModel {
  final String id;
  final String ticketId;
  final String? content;
  final String? dateCreation;
  final String? dateMod;
  final String? userId;
  final String? status;

  SolutionModel({
    required this.id,
    required this.ticketId,
    this.content,
    this.dateCreation,
    this.dateMod,
    this.userId,
    this.status,
  });

  factory SolutionModel.fromJson(Map<String, dynamic> json) {
    return SolutionModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['tickets_id']?.toString() ?? '',
      content: json['content']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMod: json['date_mod']?.toString(),
      userId: json['users_id']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
