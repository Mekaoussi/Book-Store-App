import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:bookstore/getting_books/books_provider.dart';
import 'package:bookstore/getting_books/api_service.dart';
import 'package:bookstore/getting_books/data_models.dart';
import 'package:bookstore/services/download_service.dart';
import 'package:bookstore/providers/navigation_provider.dart';
import 'package:bookstore/providers/cart_provider.dart';
import 'package:bookstore/providers/history_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BookAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserBookInteractionAdapter());
    }

    // Open necessary boxes
    await Hive.openBox('userBox');

    // Initialize download service with new box structure
    final downloadService = DownloadService();
    await downloadService.initializeBoxes();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => BookProvider(apiService: ApiService()),
          ),
          Provider(
            create: (context) => downloadService,
          ),
          ChangeNotifierProvider(
            create: (context) => NavigationProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => CartProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => HistoryProvider(),
          ),
        ],
        child: const BookStore(),
      ),
    );
  } catch (e) {
    print('Error during initialization: $e');

    runApp(const ErrorApp());
  }
}

class BookStore extends StatelessWidget {
  const BookStore({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      title: 'Book Store',
      debugShowCheckedModeBanner: false,
      home: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
          return navigationProvider.currentPage;
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app. Please restart.',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }
}
