// api_service.dart
import 'dart:convert';
import 'package:bookstore/base_url.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getAllBooks() async {
    String? token = await _storage.read(key: "token");
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = "${baseUrl}get_all_books/";
    print("Debug: Fetching books from $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      print("Debug: Response status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Debug: Response body: ${response.body}");
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      print("Debug: Network error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateReadingProgress(
      int bookId, int currentPage) async {
    final token = await _storage.read(key: 'token');

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}update_progress/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'book_id': bookId,
              'current_page': currentPage,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return data;
      } else {
        throw Exception('Failed to update progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> toggleFavorite(int bookId) async {
    final token = await _storage.read(key: 'token');

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}toggle_favorite/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'book_id': bookId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> syncOfflineReadingProgress(
      List<Map<String, dynamic>> progressUpdates) async {
    print('Debug: Starting batch sync of reading progress');
    final token = await _storage.read(key: 'token');

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}sync_reading_progress/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'progress_updates': progressUpdates,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('Debug: Batch sync response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            'Debug: Batch sync successful, updated ${progressUpdates.length} books');
        return data;
      } else {
        throw Exception(
            'Failed to sync reading progress: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug: API error during batch sync - $e');
      throw Exception('Network error during batch sync: $e');
    }
  }

  Future<Map<String, dynamic>> searchBooks(String query) async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('${baseUrl}search_books/?query=$query'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to search books: ${response.statusCode}');
    }
  }
}
