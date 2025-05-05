import 'dart:async';
import 'dart:io';

import 'package:bookstore/account_inof_page/account_info_page.dart';
import 'package:bookstore/book_product/book_product_page.dart';
import 'package:bookstore/drawer_pages/collection.dart';
import 'package:bookstore/drawer_pages/history_page.dart';
import 'package:bookstore/getting_books/books_provider.dart';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:bookstore/home_page/product.dart';
import 'package:bookstore/sign_pages/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:bookstore/cart/cart_sheet.dart';
import 'package:bookstore/providers/cart_provider.dart';
import 'search_results_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

const _storage = FlutterSecureStorage();

class _HomePageState extends State<HomePage> {
  late final BookProvider _bookProvider;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Box userBox;
  String? _imagePath;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    userBox = Hive.box('userBox');
    _bookProvider = context.read<BookProvider>();
    _loadProfileImage();
    scheduleMicrotask(() {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    print('Debug: Starting _initializeData()');
    try {
      // First try to sync any offline reading progress
      await _bookProvider.syncOfflineReadingProgress();

      // Then fetch all books (which will include the updated progress)
      await _bookProvider.fetchBooks();

      if (mounted) {
        setState(() {});
      }
      debugPrint('Debug: Successfully fetched books');
    } catch (e) {
      debugPrint('Error loading books: $e');
      // Show a snackbar if there's an error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load books: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onRefresh() async {
    try {
      await _initializeData();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      String? imagePath = userBox.get('profile_image');
      if (imagePath != null && File(imagePath).existsSync()) {
        setState(() {
          _imagePath = imagePath;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  void _updateProfileImage() {
    // Clear the entire image cache to ensure no stale images
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Get the latest image path from Hive
    String? savedImagePath = userBox.get('profile_image', defaultValue: null);

    // Force rebuild with new image path
    setState(() {
      _imagePath = null; // First set to null to force widget rebuild
    });

    // Use a delayed setState to ensure the widget tree is refreshed
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _imagePath = savedImagePath;
        });
      }
    });
  }

  Widget headeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: const ImageIcon(
                AssetImage('assets/icons/account.png'),
                size: 35,
              ),
            );
          },
        ),
        const SizedBox(
          height: 40,
          width: 150,
          child: Image(
            image: AssetImage('assets/icons/logo.png'),
          ),
        ),
        GestureDetector(
          onTap: () => showCartSheet(context),
          child: Stack(
            children: [
              const ImageIcon(
                AssetImage('assets/icons/market.png'),
                size: 35,
              ),
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return cartProvider.items.isEmpty
                      ? const SizedBox()
                      : Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProvider.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget drawer() {
    final username = userBox.get('username', defaultValue: "") as String;

    return Drawer(
      child: Container(
        color: const Color.fromARGB(255, 232, 236, 240),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 154, 49, 247),
              ),
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      key: ValueKey('profile-${_imagePath ?? "default"}'),
                      radius: 45,
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!)) as ImageProvider
                          : const AssetImage('assets/images/me.jpg'),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      username,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255)),
                    )
                  ],
                ),
              ),
            ),
            Container(
              color: const Color.fromARGB(255, 232, 236, 240),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AccountInfoPage()));

                      _updateProfileImage();

                      // Close and reopen the drawer to force a rebuild
                      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                        Navigator.pop(context); // Close drawer
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _scaffoldKey.currentState
                              ?.openDrawer(); // Reopen drawer
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.person),
                          SizedBox(width: 10),
                          Text('Account Info'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  // Add History option here
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryPage()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.history),
                          SizedBox(width: 10),
                          Text('Recently Visited'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Collection(
                                    tabPageIndex: 1,
                                  )));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.add_business_rounded),
                          SizedBox(width: 10),
                          Text('My Orders'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Collection(
                                    tabPageIndex: 0,
                                  )));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.favorite),
                          SizedBox(width: 10),
                          Text('My Favourites'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  // ✅ FINAL VERSION ✅
                  // Only one Downloads option is needed
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Collection(
                                    tabPageIndex: 2,
                                  )));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.download),
                          SizedBox(width: 10),
                          Text('Downloads'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  // ✅ FINAL VERSION ✅
                  GestureDetector(
                    onTap: () {
                      clearUserData();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    height: 1,
                  ),
                  // Remove the ListTile for History here since we've added it above
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> clearUserData() async {
    try {
      String? imagePath = userBox.get('profile_image');

      if (imagePath != null && File(imagePath).existsSync()) {
        await File(imagePath).delete();
        debugPrint("Profile image deleted.");
      }

      await _storage.delete(key: 'token');

      await userBox.clear();

      debugPrint("Token and user data successfully deleted.");
    } catch (e) {
      debugPrint("Error clearing user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color.fromARGB(255, 232, 236, 240),
        drawer: drawer(),
        body: SafeArea(
          child: SmartRefresher(
            enablePullDown: true,
            header: const WaterDropHeader(
              waterDropColor: Color.fromARGB(255, 154, 49, 247),
              complete: Icon(Icons.check, color: Colors.green),
              failed: Icon(Icons.error, color: Colors.red),
            ),
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    children: [headeRow(), _buildSearchField()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 5,
                  ),
                  child: TabBar(
                    labelPadding: const EdgeInsets.only(right: 10),
                    dividerHeight: 1,
                    dividerColor:
                        const Color.fromARGB(255, 35, 31, 36).withOpacity(0),
                    indicatorColor: const Color.fromARGB(255, 152, 72, 178)
                        .withOpacity(0.7),
                    labelColor: const Color.fromARGB(255, 152, 72, 178),
                    isScrollable: false,
                    splashBorderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                    tabs: const [
                      Tab(
                        child: Text(
                          "Pour vous",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Nouveautés",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Meilleurs ventes",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<BookProvider>(
                    builder: (context, bookProvider, child) {
                      if (bookProvider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (bookProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off,
                                  size: 48, color: Colors.orange),
                              const SizedBox(height: 16),
                              Text(
                                bookProvider.error!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _initializeData(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final forYouBooks = bookProvider.forYouBooks;
                      final newBooks = bookProvider.newBooks;
                      final favoriteBooks = bookProvider.favoriteBooks;
/*
                      print('Debug: For You Books - ${forYouBooks.length}');
                      print('Debug: New Books - ${newBooks.length}');
                      print('Debug: Favorite Books - ${favoriteBooks.length}');
*/
                      final books = [forYouBooks, newBooks, favoriteBooks];

                      // If no books in any tab, show error
                      if (books.every((tabBooks) => tabBooks.isEmpty)) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                bookProvider.error ?? 'No books available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  debugPrint('Debug: Retrying book fetch...');
                                  _initializeData();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      return TabBarView(
                        children: books
                            .map((tabBooks) => tabBooks.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.library_books_outlined,
                                            size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No books in this category',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ProductsGrid(
                                    books: tabBooks,
                                    bookProvider: bookProvider))
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          // Only prepare the search results without navigating
          if (query.length >= 2) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              // Get the BookProvider instance and call search method
              final bookProvider =
                  Provider.of<BookProvider>(context, listen: false);
              bookProvider.searchBooks(query);
              // No navigation here
            });
          }
        },
        onSubmitted: (query) {
          // Navigate only when user presses enter/search button
          if (query.length >= 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsPage(searchQuery: query),
              ),
            );
          }
        },
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Search for books...",
          hintStyle: const TextStyle(
            fontSize: 15,
            fontFamily: "lato",
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 240, 240, 242),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 152, 72, 178),
            ),
            borderRadius: BorderRadius.all(Radius.circular(11)),
          ),
          // Add a search button that triggers navigation
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  final query = _searchController.text;
                  if (query.length >= 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchResultsPage(searchQuery: query),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsGrid extends StatefulWidget {
  final List<Book> books;
  final BookProvider bookProvider;

  const ProductsGrid(
      {super.key, required this.books, required this.bookProvider});

  @override
  ProductsGridState createState() => ProductsGridState();
}

class ProductsGridState extends State<ProductsGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
        color: const Color.fromARGB(230, 245, 245, 245),
        border: Border(
            top: const BorderSide(
                color: Color.fromARGB(255, 152, 72, 178), width: 1.2),
            left: BorderSide(
                color: const Color.fromARGB(255, 152, 72, 178).withOpacity(0.7),
                width: 1),
            right: BorderSide(
                color: const Color.fromARGB(255, 152, 72, 178).withOpacity(0.7),
                width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 0, right: 5, left: 5),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 0.65),
          itemCount: widget.books.length,
          itemBuilder: (context, index) {
            Book book = widget.books[index];

            bool isFavorite = book.isFavorite;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookProductPage(
                      book: book,
                      source: 'provider', // Explicitly set source
                    ),
                  ),
                );
              },
              child: Product(
                name: widget.books[index].title,
                assetLink: widget.books[index].coverImage,
                likedOrNot: isFavorite,
                totalRating: widget.books[index].totalRating,
              ),
            );
          },
        ),
      ),
    );
  }
}
