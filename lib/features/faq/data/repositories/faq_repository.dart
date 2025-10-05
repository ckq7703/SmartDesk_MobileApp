import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../domain/models/faq_model.dart';
import '../../domain/models/faq_category_model.dart';

class FaqRepository {
  final ApiClient apiClient;
  static const int itemsPerPage = 50;

  FaqRepository(this.apiClient);

  Future<List<FaqModel>> getFaqs({int start = 0, int limit = 50}) async {
    final response = await apiClient.get(
      '/apirest.php/KnowbaseItem/?range=$start-${start + limit}',
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);

      if (data is List) {
        return data.map((json) => FaqModel.fromJson(json)).toList();
      }
      return [];
    }

    throw Exception('Failed to load FAQs');
  }

  Future<List<FaqCategoryModel>> getFaqCategories({
    int start = 0,
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      '/apirest.php/KnowbaseItemCategory/?range=$start-${start + limit}',
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);

      if (data is List) {
        return data.map((json) => FaqCategoryModel.fromJson(json)).toList();
      }
      return [];
    }

    throw Exception('Failed to load FAQ categories');
  }

  Future<FaqModel> getFaqDetail(String faqId) async {
    final response = await apiClient.get(
      '/apirest.php/KnowbaseItem/$faqId',
    );

    if (response.statusCode == 200) {
      final String responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      return FaqModel.fromJson(data);
    }

    throw Exception('Failed to load FAQ detail');
  }
}
