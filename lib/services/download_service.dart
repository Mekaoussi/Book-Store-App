import 'dart:io';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DownloadService {
  static const String downloadedBooksBoxName = 'downloadedBooks';
  static const String downloadedPdfsBoxName = 'downloadedPdfs';

  static const String downloadedCoversBoxName = 'downloadedCovers';
  // Removed downloadedInteractionsBoxName

  final Dio _dio = Dio();
  bool _boxesInitialized = false;

  Future<void> initializeBoxes() async {
    if (_boxesInitialized) return;

    try {
      if (!Hive.isBoxOpen(downloadedBooksBoxName)) {
        await Hive.openBox<Book>(downloadedBooksBoxName);
      }
      if (!Hive.isBoxOpen(downloadedPdfsBoxName)) {
        await Hive.openBox<String>(downloadedPdfsBoxName);
      }
      if (!Hive.isBoxOpen(downloadedCoversBoxName)) {
        await Hive.openBox<String>(downloadedCoversBoxName);
      }

      _boxesInitialized = true;
    } catch (e) {
      print('Error initializing Hive boxes: $e');
      // Try to recover by closing all boxes and reinitializing
      await closeBoxes();
      rethrow;
    }
  }

  Future<void> closeBoxes() async {
    try {
      if (Hive.isBoxOpen(downloadedBooksBoxName)) {
        await Hive.box(downloadedBooksBoxName).close();
      }
      if (Hive.isBoxOpen(downloadedPdfsBoxName)) {
        await Hive.box(downloadedPdfsBoxName).close();
      }
      if (Hive.isBoxOpen(downloadedCoversBoxName)) {
        await Hive.box(downloadedCoversBoxName).close();
      }
      _boxesInitialized = false;
    } catch (e) {
      print('Error closing Hive boxes: $e');
    }
  }

  Future<bool> downloadBook(Book book) async {
    try {
      await initializeBoxes();

      final booksBox = Hive.box<Book>(downloadedBooksBoxName);
      final pdfsBox = Hive.box<String>(downloadedPdfsBoxName);
      final coversBox = Hive.box<String>(downloadedCoversBoxName);

      final appDir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${appDir.path}/books/${book.id}');
      if (!bookDir.existsSync()) {
        bookDir.createSync(recursive: true);
      }

      // Create subdirectories for PDF and cover
      final pdfDir = Directory('${bookDir.path}/pdffile');
      final coverDir = Directory('${bookDir.path}/cover');
      if (!pdfDir.existsSync()) pdfDir.createSync();
      if (!coverDir.existsSync()) coverDir.createSync();

      String? localPdfPath;
      String? localCoverPath;

      // Download PDF if available
      if (book.pdfUrl != null) {
        localPdfPath = '${pdfDir.path}/book.pdf';
        await _dio.download(book.pdfUrl!, localPdfPath);
        await pdfsBox.put(book.id.toString(), localPdfPath);
      }

      // Download cover image if available
      if (book.coverImage.isNotEmpty) {
        localCoverPath = '${coverDir.path}/cover.jpg';
        final response = await http.get(Uri.parse(book.coverImage));
        await File(localCoverPath).writeAsBytes(response.bodyBytes);
        await coversBox.put(book.id.toString(), localCoverPath);
      }

      // Update book with local paths and save
      final updatedBook = book.copyWith(
        localPdfPath: localPdfPath,
        localCoverPath: localCoverPath,
        downloadedAt: DateTime.now(),
        isInLibrary: true,
      );
      await booksBox.put(book.id.toString(), updatedBook);

      return true;
    } catch (e) {
      print('Error downloading book: $e');
      return false;
    }
  }

  // ✅ FINAL VERSION ✅
  Future<void> updateBookProgress(Book book) async {
    try {
      await initializeBoxes();
      final booksBox = Hive.box<Book>(downloadedBooksBoxName);

      // Only update if the book is already in the box
      if (booksBox.containsKey(book.id.toString())) {
        // Get existing book to preserve other properties
        final existingBook = booksBox.get(book.id.toString());
        if (existingBook != null) {
          // Create updated book with new progress but keeping other properties
          final updatedBook = existingBook.copyWith(
            currentPage: book.currentPage,
            readProgress: book.readProgress,
            lastReadAt: DateTime.now(),
          );
          await booksBox.put(book.id.toString(), updatedBook);
          print(
              'Debug: Updated book ${book.id} in Hive with progress ${updatedBook.readProgress}%');
        }
      } else {
        print(
            'Debug: Book ${book.id} not found in Hive, cannot update progress');
      }
    } catch (e) {
      print('Error updating book progress in Hive: $e');
      throw e; // Re-throw to allow caller to handle
    }
  }
  // ✅ FINAL VERSION ✅

  Future<List<Book>> getDownloadedBooks() async {
    try {
      if (!Hive.isBoxOpen(downloadedBooksBoxName)) {
        await initializeBoxes();
      }

      final booksBox = Hive.box<Book>(downloadedBooksBoxName);
      return booksBox.values.where((book) => book.isInLibrary).toList();
    } catch (e) {
      print('Error getting downloaded books: $e');
      // Try to recover by reinitializing
      await closeBoxes();
      await initializeBoxes();
      try {
        final booksBox = Hive.box<Book>(downloadedBooksBoxName);
        return booksBox.values.where((book) => book.isInLibrary).toList();
      } catch (e) {
        print('Failed to recover downloaded books: $e');
        return [];
      }
    }
  }

  Future<bool> isBookDownloaded(int bookId) async {
    try {
      // Ensure boxes are initialized
      await initializeBoxes();

      final booksBox = Hive.box<Book>(downloadedBooksBoxName);
      final pdfsBox = Hive.box<String>(downloadedPdfsBoxName);

      // Check if book exists in both boxes and has isInLibrary flag
      if (booksBox.containsKey(bookId.toString()) &&
          pdfsBox.containsKey(bookId.toString())) {
        final book = booksBox.get(bookId.toString());
        return book != null && book.isInLibrary;
      }
      return false;
    } catch (e) {
      print('Error checking if book is downloaded: $e');
      return false;
    }
  }

  Future<void> deleteDownloadedBook(int bookId) async {
    try {
      await initializeBoxes();

      final booksBox = Hive.box<Book>(downloadedBooksBoxName);
      final pdfsBox = Hive.box<String>(downloadedPdfsBoxName);
      final coversBox = Hive.box<String>(downloadedCoversBoxName);

      // Get the book
      final book = booksBox.get(bookId.toString());
      if (book == null) return;

      // Delete the book directory and all its contents
      final appDir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${appDir.path}/books/$bookId');
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }

      // Remove file paths from the respective boxes
      await pdfsBox.delete(bookId.toString());
      await coversBox.delete(bookId.toString());

      // Completely remove the book from the books box instead of just updating it
      await booksBox.delete(bookId.toString());

      print('Successfully deleted book $bookId from downloads');
    } catch (e) {
      print('Error deleting downloaded book: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<String?> getLocalPdfPath(int bookId) async {
    try {
      await initializeBoxes();
      final pdfsBox = Hive.box<String>(downloadedPdfsBoxName);
      return pdfsBox.get(bookId.toString());
    } catch (e) {
      print('Error getting local PDF path: $e');
      return null;
    }
  }

  Future<String?> getLocalCoverPath(int bookId) async {
    try {
      await initializeBoxes();
      final coversBox = Hive.box<String>(downloadedCoversBoxName);
      return coversBox.get(bookId.toString());
    } catch (e) {
      print('Error getting local cover path: $e');
      return null;
    }
  }

  Future<String?> downloadTemporaryPdf(String? pdfUrl, int bookId) async {
    if (pdfUrl == null) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDir.path}/temppdf');
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }

      final localPath = '${tempDir.path}/temp_${bookId}.pdf';
      await _dio.download(pdfUrl, localPath);
      return localPath;
    } catch (e) {
      print('Error downloading temporary PDF: $e');
      return null;
    }
  }

  Future<void> cleanupTemporaryPdfs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDir.path}/temppdf');
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up temporary PDFs: $e');
    }
  }
}
