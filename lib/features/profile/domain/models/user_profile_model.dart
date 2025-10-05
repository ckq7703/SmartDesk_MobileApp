class UserProfileModel {
  final String userId;
  final String username;
  final String realName;
  final String firstName;
  final String friendlyName;
  final String language;
  final String profileName;
  final String entityName;
  final String dateFormat;
  final String numberFormat;
  final int listLimit;

  UserProfileModel({
    required this.userId,
    required this.username,
    required this.realName,
    required this.firstName,
    required this.friendlyName,
    required this.language,
    required this.profileName,
    required this.entityName,
    required this.dateFormat,
    required this.numberFormat,
    required this.listLimit,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>;
    final activeProfile = session['glpiactiveprofile'] as Map<String, dynamic>?;

    return UserProfileModel(
      userId: session['glpiID']?.toString() ?? '',
      username: session['glpiname']?.toString() ?? '',
      realName: session['glpirealname']?.toString() ?? '',
      firstName: session['glpifirstname']?.toString() ?? '',
      friendlyName: session['glpifriendlyname']?.toString() ?? '',
      language: session['glpilanguage']?.toString() ?? 'en_US',
      profileName: activeProfile?['name']?.toString() ?? '',
      entityName: session['glpiactive_entity_name']?.toString() ?? '',
      dateFormat: session['glpidate_format']?.toString() ?? '0',
      numberFormat: session['glpinumber_format']?.toString() ?? '0',
      listLimit: int.tryParse(session['glpilist_limit']?.toString() ?? '20') ?? 20,
    );
  }

  String get fullName {
    if (firstName.isNotEmpty && realName.isNotEmpty) {
      return '$firstName $realName';
    } else if (friendlyName.isNotEmpty) {
      return friendlyName;
    }
    return username;
  }

  String get initials {
    if (firstName.isNotEmpty && realName.isNotEmpty) {
      return '${firstName[0]}${realName[0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : 'U';
  }
}
