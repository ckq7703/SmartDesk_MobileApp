class FollowupModel {
  final String id;
  final String ticketId;
  final String userId;
  final String? content;
  final String? dateCreation;
  final String? dateMod;
  final String? isPrivate;

  FollowupModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    this.content,
    this.dateCreation,
    this.dateMod,
    this.isPrivate,
  });

  factory FollowupModel.fromJson(Map<String, dynamic> json) {
    return FollowupModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['items_id']?.toString() ?? json['tickets_id']?.toString() ?? '',
      // ✅ users_id đã là string name rồi khi dùng expand_dropdowns=true
      userId: json['users_id']?.toString() ?? 'Unknown',
      content: json['content']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMod: json['date_mod']?.toString(),
      isPrivate: json['is_private']?.toString(),
    );
  }
}
