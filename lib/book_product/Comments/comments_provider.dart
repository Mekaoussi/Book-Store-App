import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bookstore/base_url.dart';
import 'package:bookstore/book_product/Comments/commentsSheet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommentsProvider extends ChangeNotifier {
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  final storage = const FlutterSecureStorage();

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch comments for a specific book
  Future<void> fetchComments(String bookId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('${baseUrl}get_book_comments/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'book_id': bookId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments = data.map((json) => Comment.fromJson(json)).toList();
      } else {
        _error = 'Failed to load comments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch replies for a specific comment
  Future<void> fetchReplies(String commentId) async {
    // Find the comment in our list
    final commentIndex = _comments.indexWhere((c) => c.id == commentId);
    if (commentIndex == -1) return;

    // Set loading state for this comment
    _comments[commentIndex].is_open = true;
    notifyListeners();

    try {
      final token = await storage.read(key: 'token');

      final response = await http.post(
        Uri.parse('${baseUrl}get_comment_replies/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'comment_id': commentId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _comments[commentIndex].replies =
            data.map((json) => Comment.fromJson(json)).toList();
      } else {
        // If error, still keep is_open true but with empty replies
        _comments[commentIndex].replies = [];
      }
    } catch (e) {
      // If error, still keep is_open true but with empty replies
      _comments[commentIndex].replies = [];
    }

    notifyListeners();
  }

  // Toggle the is_open state of a comment
  void toggleCommentReplies(String commentId) {
    final commentIndex = _comments.indexWhere((c) => c.id == commentId);
    if (commentIndex == -1) return;

    final comment = _comments[commentIndex];

    // If it's closed and has no replies yet, fetch them
    if (!comment.is_open && comment.replies.isEmpty) {
      fetchReplies(commentId);
    } else {
      // Otherwise just toggle the state
      _comments[commentIndex].is_open = !comment.is_open;
      notifyListeners();
    }
  }

  // Add a new comment
  Future<bool> addComment(String bookId, String content,
      {String? parentId, String? repliedToUsername}) async {
    try {
      final token = await storage.read(key: 'token');

      // Modify content to include @username if replying
      String finalContent = content;
      if (repliedToUsername != null) {
        finalContent = "@$repliedToUsername $content";
      }

      final Map<String, dynamic> requestBody = {
        'book_id': bookId,
        'content': finalContent,
      };

      if (parentId != null) {
        requestBody['parent_id'] = parentId;
      }

      final response = await http.post(
        Uri.parse('${baseUrl}add_comment/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        // If it's a reply, fetch replies for the parent comment
        if (parentId != null) {
          final commentIndex = _comments.indexWhere((c) => c.id == parentId);
          if (commentIndex != -1) {
            await fetchReplies(parentId);
          }
        } else {
          // Otherwise refresh all comments
          await fetchComments(bookId);
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
