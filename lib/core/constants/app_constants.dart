class AppConstants {
  static const String appTitle = 'SmartDesk Mobile';
  static const String defaultBaseUrl = 'https://smartdesk.smartpro.edu.vn/';
}

class ApiConstants {
  static const String initSession = '/apirest.php/initSession';
  static const String getFullSession   = '/apirest.php/initSession?get_full_session=true';

  static const String killSession = '/apirest.php/killSession'; // ✅ Thêm này
  static const String ticketEndpoint = '/apirest.php/Ticket/';
  static const String entityEndpoint = '/apirest.php/Entity/';
}

