class SessionModel {
  final String sessionToken;
  final String baseUrl;
  final String userId;
  final String username;


  SessionModel({
    required this.sessionToken,
    required this.baseUrl,
    required this.userId,
    required this.username,
  });

  // ✅ Convert to JSON
  Map<String, dynamic> toJson() => {
    'sessionToken': sessionToken,
    'baseUrl': baseUrl,
    'userId':       userId,
    'username':     username,
  };

  // ✅ Create from JSON
  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    sessionToken: json['sessionToken'] as String,
    baseUrl: json['baseUrl'] as String,
    userId:       json['userId']       as String,
    username:     json['username']     as String,
  );
}
