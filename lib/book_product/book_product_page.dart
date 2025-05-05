import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/book_product/Comments/commentsSheet.dart';
import 'package:bookstore/book_product/Comments/random_comment.dart';
import 'package:bookstore/getting_books/book_reader_flow.dart';
import 'package:bookstore/getting_books/books_provider.dart';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:bookstore/services/download_service.dart';
import 'package:bookstore/providers/cart_provider.dart';
import 'package:bookstore/cart/cart_sheet.dart';
import 'package:bookstore/providers/history_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class BookProductPage extends StatefulWidget {
  final Book book;
  final String source;

  const BookProductPage({
    super.key,
    required this.book,
    this.source = 'provider',
  });

  @override
  State<BookProductPage> createState() => _BookProductPageState();
}

class _BookProductPageState extends State<BookProductPage> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloading = false;
  late Book _displayBook;

  @override
  void initState() {
    super.initState();

    // Record this book visit in history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false)
          .addBookToHistory(widget.book);
    });

    _displayBook = widget.book;
    _loadBookData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when dependencies change (like when returning from reader)
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    try {
      // Always get the latest data from provider first
      if (mounted && context.mounted) {
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        final providerBook = bookProvider.getBookById(widget.book.id);

        if (providerBook != null) {
          // If we're in provider source, update display book from provider
          if (widget.source != 'hive') {
            setState(() {
              _displayBook = providerBook;
            });
            debugPrint(
                'Updated display book from provider: ${providerBook.readProgress}%');
          }
        }
      }

      // For Hive source, always get the latest downloaded data
      if (await _downloadService.isBookDownloaded(widget.book.id)) {
        final downloadedBooks = await _downloadService.getDownloadedBooks();
        final hiveBook = downloadedBooks.firstWhere(
          (book) => book.id == widget.book.id,
          orElse: () => widget.book,
        );

        if (mounted) {
          // If we're in hive source, update display book from hive
          if (widget.source == 'hive') {
            setState(() {
              _displayBook = hiveBook;
            });
            debugPrint(
                'Updated display book from Hive: ${hiveBook.readProgress}%');
          }
        }
      } else if (widget.source == 'hive' && mounted) {
        // If book is not downloaded but we're in 'hive' source,
        // reset to original book data or provider data if available
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        final providerBook = bookProvider.getBookById(widget.book.id);

        setState(() {
          _displayBook = providerBook ?? widget.book;
        });
        debugPrint(
            'Book not downloaded, using provider data: ${_displayBook.readProgress}%');
      }
    } catch (e) {
      debugPrint('Error loading book data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use the display book when source is 'hive' (downloads)
    // ignore: unused_local_variable
    final book = widget.source == 'hive'
        ? _displayBook
        : Provider.of<BookProvider>(context).getBookById(widget.book.id) ??
            widget.book;

    return Scaffold(
      backgroundColor: const Color.fromARGB(250, 240, 240, 240),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                widget.book.isPaid
                    ? _buildActionButtons()
                    : Consumer<CartProvider>(
                        builder: (context, cartProvider, child) {
                          final bool isInCart = cartProvider.items
                              .any((item) => item.bookId == widget.book.id);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!isInCart) {
                                      cartProvider.addToCart(widget.book);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${widget.book.title} added to cart'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      showCartSheet(context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isInCart
                                        ? const Color.fromARGB(255, 64, 138, 32)
                                        : const Color.fromARGB(255, 53, 132,
                                            234), // Changed to blue
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          isInCart
                                              ? Icons.shopping_cart_checkout
                                              : Icons.shopping_cart,
                                          color: Colors.white,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Add to Cart',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 15),
                _buildRatingSection(),
                const SizedBox(height: 15),
                if (widget.source != 'hive')
                  GestureDetector(
                      onTap: () {
                        showCommentsSheet(context, widget.book.id.toString());
                      },
                      child: buildcomment()),
                const SizedBox(height: 24),
                _buildGenresSection(widget.book),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBioSection(),
                      const SizedBox(height: 24),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      actions: [
        if (widget.source != 'hive')
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Consumer<BookProvider>(
              builder: (context, bookProvider, child) {
                final book =
                    bookProvider.getBookById(widget.book.id) ?? widget.book;
                final isFavorite = book.isFavorite;

                return GestureDetector(
                  onTap: () async {
                    await FavoriteService()
                        .toggleFavorite(widget.book.id, context);
                    // No setState needed - Provider will handle the UI update
                  },
                  child: Image(
                    image: isFavorite
                        ? const AssetImage('assets/icons/selected_heart.png')
                        : const AssetImage('assets/icons/unselected_heart.png'),
                    color: isFavorite
                        ? const Color.fromARGB(255, 234, 68, 68)
                        : const Color.fromARGB(255, 230, 230, 230),
                    width: 35,
                  ),
                );
              },
            ),
          )
      ],
      iconTheme: const IconThemeData(color: Colors.white),
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: const Color.fromARGB(250, 240, 240, 240),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.source == 'hive' && _displayBook.localCoverPath != null
                ? Image.file(
                    File(_displayBook.localCoverPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.network(
                      widget.book.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey),
                    ),
                  )
                : Image.network(
                    widget.book.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey),
                  ),

            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildBookHeader(widget.book.totalRating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeader(double totalRating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          children: [
            widget.source != 'hive'
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Column(
                      children: [
                        SizedBox(
                            height: 45,
                            width: 80,
                            child: Image.asset("assets/icons/total_score.png")),
                        Consumer<BookProvider>(
                          builder: (context, bookProvider, child) {
                            Book? book =
                                bookProvider.getBookById(widget.book.id);
                            return Text(
                              book?.totalRating.toString() ?? "0.0",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 220, 220, 220),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : Consumer<BookProvider>(
                    builder: (context, bookProvider, child) {
                      // Get the correct book based on source
                      final Book bookToUse = widget.source == 'hive'
                          ? _displayBook
                          : bookProvider.getBookById(widget.book.id) ??
                              widget.book;

                      final progress =
                          bookToUse.readProgress.clamp(0.0, 100.0) / 100.0;
                      final progressPercent = bookToUse.readProgress.round();

                      debugPrint(
                          'Debug: UI progress for book ${bookToUse.id}: $progressPercent% (raw: $progress), source: ${widget.source}');

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(200, 0, 180, 0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.book_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "$progressPercent%",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Hero(
                tag: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: widget.source == 'hive' &&
                          _displayBook.localCoverPath != null
                      ? Image.file(
                          File(_displayBook.localCoverPath!),
                          width: 140,
                          height: 210,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(
                            widget.book.coverImage,
                            width: 140,
                            height: 210,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey),
                          ),
                        )
                      : Image.network(
                          widget.book.coverImage,
                          width: 140,
                          height: 210,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.grey),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(child: _buildBookDetails()),
      ],
    );
  }

  Widget _buildBookDetails() {
    const TextStyle labelStyle = TextStyle(
      fontSize: 16,
      color: Colors.white70,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.book.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.author,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Release:', widget.book.publicationDate, labelStyle),
        _buildInfoRow('Pages:', widget.book.pageCount.toString(), labelStyle),
        _buildInfoRow('ISBN:', widget.book.isbn, labelStyle),
        _buildInfoRow('Price:', 'DZD ${widget.book.price.toStringAsFixed(2)}',
            labelStyle),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: style.copyWith(fontWeight: FontWeight.w300),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: style.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: label == "ISBN:" ? 13 : 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (widget.book.pdfUrl != null) {
                      // Get the latest book data before opening reader
                      Book bookToRead = widget.source == 'hive'
                          ? _displayBook
                          : Provider.of<BookProvider>(context, listen: false)
                                  .getBookById(widget.book.id) ??
                              widget.book;

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfReader(
                            book: bookToRead,
                          ),
                        ),
                      );

                      // Force refresh data when returning from reader
                      if (mounted) {
                        await _loadBookData();
                        setState(() {}); // Force UI update
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No PDF available for this book'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 53, 132, 234), // Changed to blue
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 3, // Added elevation for better depth
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Start Reading',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const SizedBox(width: 16),
              Builder(builder: (context) {
                // Create a key to force rebuild of FutureBuilder
                final downloadButtonKey = GlobalKey();

                return StatefulBuilder(
                  builder: (context, setButtonState) {
                    return FutureBuilder<bool>(
                      key: downloadButtonKey,
                      future: _downloadService.isBookDownloaded(widget.book.id),
                      builder: (context, snapshot) {
                        final isDownloaded = snapshot.data ?? false;

                        return Expanded(
                          child: ElevatedButton(
                            onPressed: _isDownloading
                                ? null
                                : () async {
                                    if (isDownloaded) {
                                      // Remove book from downloads
                                      try {
                                        await _downloadService
                                            .deleteDownloadedBook(
                                                widget.book.id);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Book removed from downloads'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          // Force complete rebuild to update download status
                                          setState(() {});
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to remove book: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Download book
                                      setButtonState(
                                          () => _isDownloading = true);
                                      try {
                                        final success =
                                            await _downloadService.downloadBook(
                                          widget.book,
                                        );
                                        if (success && mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Book downloaded successfully'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          // Update display book and force rebuild
                                          setState(() {
                                            _loadBookData();
                                          });
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Failed to download book'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to download book: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setButtonState(
                                              () => _isDownloading = false);
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDownloaded
                                  ? const Color.fromARGB(
                                      255, 234, 68, 53) // Red for remove
                                  : const Color.fromARGB(
                                      255, 76, 175, 80), // Green for download
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3, // Added elevation for better depth
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isDownloading
                                      ? Icons.hourglass_bottom
                                      : (isDownloaded
                                          ? Icons.delete_outline
                                          : Icons.download),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDownloading
                                      ? 'Downloading..'
                                      : (isDownloaded ? 'Remove' : 'Download'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingSection() {
    if (widget.source == 'hive') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 2,
        right: 15,
        left: 15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 200, 200, 200),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate this book',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 60, 60, 60)),
                  ),
                  RatingBar.builder(
                    initialRating: widget.book.rating ?? 0,
                    minRating: 0,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 25,
                    glow: false,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Color.fromARGB(255, 255, 193, 7),
                    ),
                    onRatingUpdate: (rating) {
                      final ratingService = RatingService();
                      ratingService.submitRating(
                          widget.book.id, rating, context);
                    },
                  ),
                ],
              ),
            ),
          ),
          Consumer<BookProvider>(
            builder: (context, bookProvider, child) {
              // Get the correct book based on source
              final Book bookToUse = widget.source == 'hive'
                  ? _displayBook
                  : bookProvider.getBookById(widget.book.id) ?? widget.book;

              final progress = bookToUse.readProgress.clamp(0.0, 100.0) / 100.0;
              final progressPercent = bookToUse.readProgress.round();

              debugPrint(
                  'Debug: UI progress for book ${bookToUse.id}: $progressPercent% (raw: $progress), source: ${widget.source}');

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(200, 0, 180, 0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.book_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$progressPercent%",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.only(right: 5, left: 5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 240, 240),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resume',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 60, 60, 60)),
          ),
          const SizedBox(height: 12),
          Text(
            widget.book.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildGenresSection(dynamic book) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    child: SizedBox(
      height: 25,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: book.genres.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 5,
              right: 5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  width: 0.5,
                ),
              ),
              child: Text(
                book.genres[index],
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class RatingService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> submitRating(
      int bookId, double rating, BuildContext context) async {
    String? token = await storage.read(key: "token");

    if (token == null) {
      print("User is not authenticated");
      return;
    }

    final url = Uri.parse("${baseUrl}submit_rating/");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "book": bookId,
          "rating": rating,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        bookProvider.updateBookRating(
            bookId, responseData['user_rating'], responseData['total_rating']);

        print("Rating submitted: ${responseData['user_rating']}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${responseData['error']}")),
        );
        print("Error submitting rating: ${responseData['error']}");
      }
    } catch (error) {
      print("Request failed: $error");
    }
  }
}

class FavoriteService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> toggleFavorite(int bookId, BuildContext context) async {
    String? token = await storage.read(key: "token");

    if (token == null) {
      print("User is not authenticated");
      return;
    }

    final url = Uri.parse("${baseUrl}toggle_favorite/");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "book_id": bookId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        // Update the provider with the new favorite status
        final bookProvider = Provider.of<BookProvider>(context, listen: false);
        bookProvider.updateFavoriteStatus(bookId, responseData['is_favorite']);

        print("Favorite status updated: ${responseData['is_favorite']}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${responseData['error']}")),
        );
        print("Error toggling favorite: ${responseData['error']}");
      }
    } catch (error) {
      print("Request failed: $error");
    }
  }
}
