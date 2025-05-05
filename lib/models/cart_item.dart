import 'package:bookstore/getting_books/data_models.dart';

class CartItem {
  final int id;
  final int bookId;
  final String title;
  final String coverImage;
  final double price;

  CartItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.coverImage,
    required this.price,
  });

  factory CartItem.fromBook(Book book) {
    return CartItem(
      id: DateTime.now().millisecondsSinceEpoch,
      bookId: book.id,
      title: book.title,
      coverImage: book.coverImage,
      price: book.price,
    );
  }
}
