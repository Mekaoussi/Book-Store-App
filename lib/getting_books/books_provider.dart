import 'dart:async';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'package:collection/collection.dart';
import 'package:bookstore/services/download_service.dart';
import 'package:flutter/widgets.dart';

class BookProvider with ChangeNotifier {
  List<Book> _allBooks = [];
  List<Book> _forYouBooks = [];
  List<Book> _newBooks = [];
  List<Book> _favoriteBooks = [];
  List<Order> _userOrders = [];
  bool _isLoading = false;
  String? _error;
  List<Book> _searchResults = [];
  bool _isSearching = false;

  // Getters
  List<Book> get allBooks => _allBooks;
  List<Book> get forYouBooks => _forYouBooks;
  List<Book> get newBooks => _newBooks;
  List<Book> get favoriteBooks => _favoriteBooks;
  List<Order> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Book> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  final ApiService apiService;

  BookProvider({required this.apiService});

  Future<void> fetchBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.getAllBooks();

      if (!data.containsKey('all_books') ||
          !data.containsKey('for_you') ||
          !data.containsKey('new_books') ||
          !data.containsKey('favorite_books')) {
        throw Exception('Invalid data structure received');
      }

      // Process all books
      _allBooks = (data['all_books'] as List)
          .map((bookJson) => Book.fromJson(bookJson))
          .toList();

      // Process for you books
      _forYouBooks = (data['for_you'] as List)
          .map((bookJson) => Book.fromJson(bookJson))
          .toList();

      // Process new books
      _newBooks = (data['new_books'] as List)
          .map((bookJson) => Book.fromJson(bookJson))
          .toList();

      // Process favorite books
      _favoriteBooks = (data['favorite_books'] as List)
          .map((bookJson) => Book.fromJson(bookJson))
          .toList();

      // Process user orders if available
      if (data.containsKey('user_orders')) {
        _userOrders = (data['user_orders'] as List)
            .map((orderJson) => Order.fromJson(orderJson))
            .toList();
      }
    } catch (e, stackTrace) {
      debugPrint('Debug: Stack trace: $stackTrace');
      _error = 'Failed to fetch books: $e';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = false;
    notifyListeners();
  }

  Book? getBookById(int id) {
    return _allBooks.firstWhereOrNull((book) => book.id == id);
  }

  Future<void> updateReadingProgress({
    required int bookId,
    required int currentPage,
  }) async {
    try {
      // 1. Update on backend
      await apiService.updateReadingProgress(bookId, currentPage);

      // 2. Find the book in our lists
      final bookIndex = _allBooks.indexWhere((book) => book.id == bookId);
      if (bookIndex == -1) return;

      final book = _allBooks[bookIndex];

      // 3. Calculate progress as a percentage (0-100)
      final progressPercent = (currentPage / book.pageCount) * 100;

      // 4. Create updated book with new progress
      final updatedBook = book.copyWith(
        currentPage: currentPage,
        readProgress: progressPercent,
        lastReadAt: DateTime.now(),
      );

      // 5. Update book in all lists
      _updateBookInAllLists(updatedBook);

      // 6. Notify listeners to update UI
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update reading progress';
      notifyListeners();
      rethrow;
    }
  }

  void _updateBookInList(List<Book> bookList, Book updatedBook) {
    final index = bookList.indexWhere((book) => book.id == updatedBook.id);
    if (index != -1) {
      bookList[index] = updatedBook;
    }
  }

  void updateFavoriteStatus(int bookId, bool isFavorite) {
    // Update book in all lists
    final book = getBookById(bookId);
    if (book == null) return;

    final updatedBook = book.copyWith(isFavorite: isFavorite);
    _updateBookInAllLists(updatedBook);

    // Update favorite books list
    if (isFavorite) {
      if (!_favoriteBooks.any((book) => book.id == bookId)) {
        _favoriteBooks.add(updatedBook);
      }
    } else {
      _favoriteBooks.removeWhere((book) => book.id == bookId);
    }

    notifyListeners();
  }

  void _updateBookInAllLists(Book updatedBook) {
    _updateBookInList(_allBooks, updatedBook);
    _updateBookInList(_forYouBooks, updatedBook);
    _updateBookInList(_newBooks, updatedBook);
    _updateBookInList(_favoriteBooks, updatedBook);
  }

  void updateBookRating(int bookId, double userRating, double totalRating) {
    final book = getBookById(bookId);
    if (book == null) return;

    final updatedBook = book.copyWith(
      rating: userRating,
      totalRating: totalRating,
    );

    _updateBookInAllLists(updatedBook);
    notifyListeners();
  }

  Future<void> syncOfflineReadingProgress() async {
    try {
      // Get download service
      final downloadService = DownloadService();

      // Get all downloaded books
      final downloadedBooks = await downloadService.getDownloadedBooks();

      // Filter books that need syncing (have been read since last sync)
      final booksToSync = downloadedBooks
          .where((book) => book.lastReadAt != null && book.currentPage > 0)
          .toList();

      if (booksToSync.isEmpty) {
        debugPrint('Debug: No books need syncing');
        return;
      }

      // Prepare batch update data
      final progressUpdates = booksToSync
          .map((book) => {
                'book_id': book.id,
                'current_page': book.currentPage,
              })
          .toList();

      // Send single batch request to backend
      await apiService.syncOfflineReadingProgress(progressUpdates);
    } catch (e) {
      debugPrint('Debug: Error syncing offline reading progress: $e');
      // Don't throw - this is a background operation that shouldn't block the UI
    }
  }

  Order? getOrderById(int id) {
    return _userOrders.firstWhereOrNull((order) => order.id == id);
  }

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      // Only notify if not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    _isSearching = true;
    _error = null;
    // Only notify if not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final data = await apiService.searchBooks(query);

      if (data.containsKey('results')) {
        _searchResults = (data['results'] as List)
            .map((bookJson) => Book.fromJson(bookJson))
            .toList();
      } else {
        _searchResults = [];
        _error = 'Invalid search results structure';
      }
    } catch (e, stackTrace) {
      debugPrint('Debug: Search error: $e');
      debugPrint('Debug: Stack trace: $stackTrace');
      _error = 'Failed to search books: $e';
      _searchResults = [];
    } finally {
      _isSearching = false;
      // Use post-frame callback to ensure we're not in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
