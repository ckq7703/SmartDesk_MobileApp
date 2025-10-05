class TicketModel {
  final String id;
  final String name;
  final String? status;
  final String? priority;
  final String? type;
  final String? content;
  final String? dateCreation;
  final String? dateMod;
  final String? usersIdRecipient;
  final String? usersIdLastupdater;

  TicketModel({
    required this.id,
    required this.name,
    this.status,
    this.priority,
    this.type,
    this.content,
    this.dateCreation,
    this.dateMod,
    this.usersIdRecipient,
    this.usersIdLastupdater,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Không có tiêu đề',
      status: json['status']?.toString(),
      priority: json['priority']?.toString(),
      type: json['type']?.toString(),
      content: json['content']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      dateMod: json['date_mod']?.toString(),
      usersIdRecipient: json['users_id_recipient']?.toString(),
      usersIdLastupdater: json['users_id_lastupdater']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'priority': priority,
      'type': type,
      'content': content,
      'date_creation': dateCreation,
      'date_mod': dateMod,
      'users_id_recipient': usersIdRecipient,
      'users_id_lastupdater': usersIdLastupdater,
    };
  }
}
