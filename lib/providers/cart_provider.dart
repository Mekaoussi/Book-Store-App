import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:bookstore/base_url.dart';
import 'package:bookstore/models/cart_item.dart';
import 'package:bookstore/getting_books/data_models.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.price);
  }

  void addToCart(Book book) {
    if (!_items.any((item) => item.bookId == book.id)) {
      _items.add(CartItem.fromBook(book));
      notifyListeners();
    }
  }

  void removeFromCart(int bookId) {
    _items.removeWhere((item) => item.bookId == bookId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> checkout(String paymentMethod) async {
    if (_items.isEmpty) {
      _error = "Your cart is empty";
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? token = await _storage.read(key: "token");
      if (token == null) {
        _error = "You need to be logged in";
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Prepare cart items in the format expected by the backend
      List<Map<String, dynamic>> cartItemsData = _items
          .map((item) => {
                "book_id": item.bookId,
                "price": item.price,
                "title": item.title,
              })
          .toList();

      final response = await http.post(
        Uri.parse("${baseUrl}create_order/"),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "payment_method": paymentMethod,
          "cart_items": cartItemsData,
          "total_amount": totalAmount,
        }),
      );

      _isLoading = false;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        clearCart(); // Clear cart after successful order
        notifyListeners();
        return data;
      } else {
        final data = jsonDecode(response.body);
        _error = data['error'] ?? "Failed to create order";
        notifyListeners();
        return null;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
