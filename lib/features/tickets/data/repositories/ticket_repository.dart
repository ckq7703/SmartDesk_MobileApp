import 'dart:convert';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/ticket_model.dart';
import '../../domain/models/followup_model.dart';
import '../../domain/models/solution_model.dart'; // ✅ Import mới

class TicketRepository {
  final ApiClient apiClient;

  TicketRepository(this.apiClient);

  Future<List<TicketModel>> getTickets({int start = 0, int limit = 99}) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.ticketEndpoint}?range=$start-${start + limit}',
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data.map((json) => TicketModel.fromJson(json)).toList();
        }

        return [];
      }

      throw Exception('Không thể tải danh sách ticket: HTTP ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TicketModel>> getRecentTickets({int limit = 5}) async {
    try {
      // GLPI API không hỗ trợ sort parameter cho Ticket endpoint
      // Nên ta lấy một số lượng tickets và sort locally
      final allTickets = await getTickets(limit: limit * 3);

      // Sort by dateMod descending (mới nhất trước)
      allTickets.sort((a, b) {
        final aDate = DateTime.tryParse(a.dateMod ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.dateMod ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      return allTickets.take(limit).toList();

    } catch (e) {
      rethrow;
    }
  }

  Future<TicketModel> getTicketDetail(String ticketId) async {
    try {
      final response = await apiClient.get(
        '${ApiConstants.ticketEndpoint}$ticketId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TicketModel.fromJson(data);
      }

      throw Exception('Không thể tải chi tiết ticket: HTTP ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FollowupModel>> getFollowups(String ticketId, {int offset = 0, int limit = 10}) async {
    try {
      final response = await apiClient.get(
          '${ApiConstants.ticketEndpoint}$ticketId/ITILFollowup?expand_dropdowns=true&range=$offset-${offset + limit - 1}'

      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => FollowupModel.fromJson(json)).toList();
        }
        return [];
      }
      print('❌ Response status: ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      return [];
    } catch (e) {
      print('❌ Error loading followups: $e');
      return [];
    }
  }




  Future<SolutionModel?> getTicketSolution(String ticketId) async {
    try {
      // ✅ Thêm expand_dropdowns=true để lấy user name
      final response = await apiClient.get(
        '${ApiConstants.ticketEndpoint}$ticketId/ITILSolution?expand_dropdowns=true',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return SolutionModel.fromJson(data[0]);
        } else if (data is Map<String, dynamic>) {
          return SolutionModel.fromJson(data);
        }

        return null;
      }

      return null;
    } catch (e) {
      return null;
    }
  }


  Future<String> getUserName(String userId) async {
    try {
      print('🔍 Fetching user name for ID: $userId');

      final response = await apiClient.get(
        '/apirest.php/User/$userId',
      );

      print('📡 User API Response status: ${response.statusCode}');
      print('📦 User API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ User data: $data');

        // Thử nhiều trường khác nhau
        final firstName = data['firstname']?.toString() ?? '';
        final realName = data['realname']?.toString() ?? '';
        final name = data['name']?.toString() ?? '';
        final userName = data['user_name']?.toString() ?? '';

        print('📝 firstName: $firstName, realName: $realName, name: $name, userName: $userName');

        if (firstName.isNotEmpty && realName.isNotEmpty) {
          return '$firstName $realName';
        } else if (realName.isNotEmpty) {
          return realName;
        } else if (firstName.isNotEmpty) {
          return firstName;
        } else if (name.isNotEmpty) {
          return name;
        } else if (userName.isNotEmpty) {
          return userName;
        }

        return 'User #$userId';
      }

      print('❌ User API failed with status: ${response.statusCode}');
      return 'User #$userId';
    } catch (e, stackTrace) {
      print('❌ Error fetching user name: $e');
      print('📍 Stack trace: $stackTrace');
      return 'User #$userId';
    }
  }



  Future<bool> addFollowup({
    required String ticketId,
    required String content,
  }) async {
    try {
      final response = await apiClient.post(
        '/apirest.php/ITILFollowup/',
        {
          'input': {
            'itemtype': 'Ticket',
            'items_id': int.parse(ticketId),
            'content': '<p>$content</p>',
          }
        },
      );

      print('Response: ${response.statusCode} - ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }




  Future<String> createTicket({
    required String name,
    required String content,
    required String type,
    required String priority,
    required String urgency,
    required String impact,
    String status = '1',
    String? categoryId,
  }) async {
    try {
      final response = await apiClient.post(
        ApiConstants.ticketEndpoint,
        {
          'input': {
            'name': name,
            'content': content,
            'type': type,
            'priority': priority,
            'urgency': urgency,
            'impact': impact,
            'status': status,
            'requesttypes_id': '1',
            if (categoryId != null) 'itilcategories_id': categoryId,
          }
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['id']?.toString() ?? 'Không xác định';
      }

      throw Exception('Không thể tạo ticket: HTTP ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }
}
