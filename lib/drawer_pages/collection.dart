import 'package:bookstore/book_product/book_product_page.dart';
import 'package:bookstore/drawer_pages/collectionTabItem.dart';
import 'package:bookstore/drawer_pages/order_item.dart' as order_widget;

import 'package:bookstore/getting_books/books_provider.dart';
import 'package:bookstore/getting_books/data_models.dart';

import 'package:bookstore/services/download_service.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Collection extends StatefulWidget {
  final int tabPageIndex;
  const Collection({super.key, required this.tabPageIndex});

  @override
  State<Collection> createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.tabPageIndex,
      length: 3,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 237, 241, 245),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 237, 241, 245),
          title: const Center(
              child: Padding(
                  padding: EdgeInsets.only(right: 50),
                  child: Text("Collection"))),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                dividerColor: Color.fromARGB(255, 152, 72, 178),
                indicatorColor: Color.fromARGB(255, 152, 72, 178),
                labelColor: Color.fromARGB(255, 152, 72, 178),
                tabAlignment: TabAlignment.center,
                isScrollable: true,
                splashBorderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
                tabs: [
                  Tab(
                    child: Text(
                      "Favoris",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Commandes",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Tab(
                    child: Text(
                      "Downloads",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  color: const Color.fromARGB(255, 220, 220, 220),
                  child: TabBarView(
                    children: [
                      _mybookslistview("fav"),
                      _myorderslistview(),
                      _downloadedBooksListView(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mybookslistview(String markedOrfav) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        List<Book> favoriteBooks = bookProvider.favoriteBooks;

        return ListView.builder(
          itemCount: favoriteBooks.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookProductPage(book: favoriteBooks[index]),
                  ),
                )
              },
              child: collectionTabItem(
                markedOrFav: markedOrfav,
                book: favoriteBooks[index],
              ),
            );
          },
        );
      },
    );
  }

  Widget _myorderslistview() {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        final orders = bookProvider.userOrders;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No orders yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your order history will appear here',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 152, 72, 178),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Browse Books'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                // Navigate to order details page if you have one
                // For now, we'll just expand/collapse the order
                setState(() {
                  // You could implement expanded state for orders here
                });
              },
              child: order_widget.OrderItem(order: orders[index]),
            );
          },
        );
      },
    );
  }

  Widget _downloadedBooksListView() {
    return FutureBuilder<List<Book>>(
      future: DownloadService().getDownloadedBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return const Center(
            child: Text(
              'No downloaded books yet',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(books[index].id.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onDismissed: (direction) async {
                try {
                  final bookTitle = books[index].title;
                  await DownloadService().deleteDownloadedBook(books[index].id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$bookTitle removed from downloads'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {
                      // Force rebuild of the list
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error removing book: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookProductPage(
                        book: books[index],
                        source: 'hive',
                      ),
                    ),
                  );
                },
                child: collectionTabItem(
                  markedOrFav: "downloads",
                  book: books[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
