import 'package:hive/hive.dart';

part 'data_models.g.dart';

@HiveType(typeId: 0)
class Book {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String author;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String coverImage;
  @HiveField(5)
  final List<String> genres;
  @HiveField(6)
  final int pageCount;
  @HiveField(7)
  final String? pdfUrl;
  @HiveField(8)
  final String? epubUrl;
  @HiveField(9)
  double readProgress;
  @HiveField(10)
  int currentPage;
  @HiveField(11)
  bool isFavorite;
  @HiveField(12)
  bool isInLibrary;
  @HiveField(13)
  DateTime? lastReadAt;
  @HiveField(14)
  double? rating;
  @HiveField(15)
  double totalRating;
  @HiveField(16)
  final String isbn;
  @HiveField(17)
  final String publicationDate;
  @HiveField(18)
  final double price;
  @HiveField(19)
  final String language;
  @HiveField(20)
  final String publisher;
  @HiveField(21)
  final int ratingsCount;
  @HiveField(22)
  final String? localPdfPath;
  @HiveField(23)
  final String? localEpubPath;
  @HiveField(24)
  final String? localCoverPath;
  @HiveField(25)
  final DateTime? downloadedAt;
  @HiveField(26)
  bool isPaid;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImage,
    required this.genres,
    required this.pageCount,
    this.pdfUrl,
    this.epubUrl,
    this.readProgress = 0.0,
    this.currentPage = 0,
    this.isFavorite = false,
    this.isInLibrary = false,
    this.isPaid = false,
    this.lastReadAt,
    this.rating,
    this.totalRating = 0.0,
    this.isbn = 'N/A',
    this.publicationDate = 'N/A',
    this.price = 0.0,
    this.language = 'English',
    this.publisher = 'Unknown',
    this.ratingsCount = 0,
    this.localPdfPath,
    this.localEpubPath,
    this.localCoverPath,
    this.downloadedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      coverImage: json['cover_image'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      pageCount: json['page_count'] ?? 0,
      pdfUrl: json['pdf_file'],
      epubUrl: json['epub_file'],
      readProgress: parseDouble(json['readProgress']) ?? 0.0,
      currentPage: json['currentPage'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      isInLibrary: json['isInLibrary'] ?? false,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'])
          : null,
      rating: parseDouble(json['rating']),
      totalRating: parseDouble(json['total_rating']) ?? 0.0,
      isbn: json['isbn'] ?? 'N/A',
      publicationDate: json['publication_date'] ?? 'N/A',
      price: parseDouble(json['price']) ?? 0.0,
      language: json['language'] ?? 'English',
      publisher: json['publisher'] ?? 'Unknown',
      ratingsCount: json['ratings_count'] ?? 0,
      isPaid: json['isPaid'] ?? false,
    );
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? description,
    String? coverImage,
    List<String>? genres,
    int? pageCount,
    String? pdfUrl,
    String? epubUrl,
    double? readProgress,
    int? currentPage,
    bool? isFavorite,
    bool? isInLibrary,
    DateTime? lastReadAt,
    double? rating,
    double? totalRating,
    String? isbn,
    String? publicationDate,
    double? price,
    String? language,
    String? publisher,
    int? ratingsCount,
    String? localPdfPath,
    String? localEpubPath,
    String? localCoverPath,
    DateTime? downloadedAt,
    bool? isPaid,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      genres: genres ?? this.genres,
      pageCount: pageCount ?? this.pageCount,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      epubUrl: epubUrl ?? this.epubUrl,
      readProgress: readProgress ?? this.readProgress,
      currentPage: currentPage ?? this.currentPage,
      isFavorite: isFavorite ?? this.isFavorite,
      isInLibrary: isInLibrary ?? this.isInLibrary,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      rating: rating ?? this.rating,
      totalRating: totalRating ?? this.totalRating,
      isbn: isbn ?? this.isbn,
      publicationDate: publicationDate ?? this.publicationDate,
      price: price ?? this.price,
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      localEpubPath: localEpubPath ?? this.localEpubPath,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

@HiveType(typeId: 1)
class UserBookInteraction {
  @HiveField(0)
  final int bookId;
  @HiveField(1)
  final double readProgress;
  @HiveField(2)
  final int currentPage;
  @HiveField(3)
  final bool isFavorite;
  @HiveField(4)
  final bool isInLibrary;
  @HiveField(5)
  final DateTime? lastReadAt;

  UserBookInteraction({
    required this.bookId,
    this.readProgress = 0.0,
    this.currentPage = 0,
    this.isFavorite = false,
    this.isInLibrary = false,
    this.lastReadAt,
  });

  factory UserBookInteraction.fromJson(int bookId, Map<String, dynamic> json) {
    // Convert percentage (0-100) to decimal (0.0-1.0)
    double progress =
        ((json['read_progress_percent'] as num?)?.toDouble() ?? 0.0) / 100.0;

    return UserBookInteraction(
      bookId: bookId,
      readProgress: progress,
      currentPage: json['current_page'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      isInLibrary: json['is_in_library'] ?? false,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.tryParse(json['last_read_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'UserBookInteraction{'
        'bookId: $bookId, '
        'readProgress: $readProgress, '
        'currentPage: $currentPage, '
        'isFavorite: $isFavorite, '
        'isInLibrary: $isInLibrary, '
        'lastReadAt: $lastReadAt'
        '}';
  }
}

class OrderItem {
  final int id;
  final int bookId;
  final String title;
  final String author;
  final String? coverImage;
  final double price;
  // Removed format property

  OrderItem({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    this.coverImage,
    required this.price,
    // Removed format parameter
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OrderItem(
      id: json['id'] ?? 0,
      bookId: json['book_id'] ?? json['book'] ?? 0,
      title: json['title'] ?? json['book_title'] ?? 'Unknown',
      author: json['author'] ?? json['book_author'] ?? 'Unknown',
      coverImage: json['cover_image'] ?? json['book_cover'],
      price: parseDouble(json['price']) ?? 0.0,
      // Removed format
    );
  }
}

class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    List<OrderItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? 'Unknown',
      totalAmount: parseDouble(json['total_amount']) ?? 0.0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'Unknown',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      items: orderItems,
    );
  }
}
