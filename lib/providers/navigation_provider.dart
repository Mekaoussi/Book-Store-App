import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bookstore/home_page/home_page.dart';
import 'package:bookstore/sign_pages/sign_in.dart';

class NavigationProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Widget _currentPage = const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 40,
            width: 150,
            child: Image(
              image: AssetImage('assets/icons/logo.png'),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(height: 20),
          Text(
            "Loading...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget get currentPage => _currentPage;

  NavigationProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    // Add 2 second delay
    await Future.delayed(const Duration(seconds: 2));

    String? token = await _storage.read(key: "token");

    _currentPage = token != null && token.isNotEmpty
        ? const HomePage()
        : const SignInPage();

    notifyListeners();
  }

  void setPage(Widget page) {
    _currentPage = page;
    notifyListeners();
  }
}
