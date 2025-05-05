import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../getting_books/data_models.dart';

class HistoryProvider with ChangeNotifier {
  static const int _maxHistoryItems = 20;
  List<Book> _recentlyVisitedBooks = [];

  List<Book> get recentlyVisitedBooks => _recentlyVisitedBooks;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final historyBox = await Hive.openBox<Map>('historyBox');
      final historyData = historyBox.get('recentlyVisitedBooks');

      if (historyData != null) {
        final List<dynamic> booksList = historyData['books'] as List;
        _recentlyVisitedBooks = booksList
            .map((bookMap) => Book.fromJson(Map<String, dynamic>.from(bookMap)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final historyBox = await Hive.openBox<Map>('historyBox');
      final booksJsonList = _recentlyVisitedBooks
          .map((book) => {
                'id': book.id,
                'title': book.title,
                'author': book.author,
                'description': book.description,
                'coverImage': book.coverImage,
                'genres': book.genres,
                'pageCount': book.pageCount,
                'pdfUrl': book.pdfUrl,
                'epubUrl': book.epubUrl,
                'readProgress': book.readProgress,
                'currentPage': book.currentPage,
                'isFavorite': book.isFavorite,
                'isInLibrary': book.isInLibrary,
                'isPaid': book.isPaid,
                'lastReadAt': book.lastReadAt?.toIso8601String(),
                'rating': book.rating,
                'totalRating': book.totalRating,
                'isbn': book.isbn,
                'publicationDate': book.publicationDate,
                'price': book.price,
                'language': book.language,
                'publisher': book.publisher,
                'ratingsCount': book.ratingsCount,
                'localPdfPath': book.localPdfPath,
                'localEpubPath': book.localEpubPath,
                'localCoverPath': book.localCoverPath,
                'downloadedAt': book.downloadedAt?.toIso8601String(),
              })
          .toList();

      await historyBox.put('recentlyVisitedBooks', {'books': booksJsonList});
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addBookToHistory(Book book) {
    // Remove the book if it already exists in history
    _recentlyVisitedBooks.removeWhere((item) => item.id == book.id);

    // Add the book to the beginning of the list
    _recentlyVisitedBooks.insert(0, book);

    // Limit the history size
    if (_recentlyVisitedBooks.length > _maxHistoryItems) {
      _recentlyVisitedBooks =
          _recentlyVisitedBooks.sublist(0, _maxHistoryItems);
    }

    notifyListeners();
    _saveHistory();
  }

  void clearHistory() {
    _recentlyVisitedBooks.clear();
    notifyListeners();
    _saveHistory();
  }
}
