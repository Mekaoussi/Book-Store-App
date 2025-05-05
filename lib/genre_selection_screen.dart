import 'package:bookstore/base_url.dart';
import 'package:bookstore/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GenreSelectionScreen extends StatefulWidget {
  final bool isNewUser;

  const GenreSelectionScreen({super.key, required this.isNewUser});

  @override
  GenreSelectionScreenState createState() => GenreSelectionScreenState();
}

class GenreSelectionScreenState extends State<GenreSelectionScreen> {
  List<String> allGenres = [];
  List<String> selectedGenres = [];
  String? token;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    loadAuthTokenAndFetchGenres();
    loadUserPreferredGenres();
  }

  void showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> loadAuthTokenAndFetchGenres() async {
    try {
      String? storedToken = await storage.read(key: 'token');
      if (storedToken == null) {
        showSnackBar("Authentication token not found!", Colors.red);
        return;
      }
      setState(() {
        token = storedToken;
      });
      await fetchGenres();
    } catch (e) {
      showSnackBar("Error loading authentication token.", Colors.red);
    }
  }

  Future<void> fetchGenres() async {
    if (token == null) return;
    try {
      var response = await http.get(
        Uri.parse('${baseUrl}get_genres/'),
        headers: {"Authorization": "Token $token"},
      );
      if (response.statusCode == 200) {
        List<dynamic> genresData = jsonDecode(response.body);
        setState(() {
          allGenres = genresData.map((g) => g['name'].toString()).toList();
        });
      } else {
        showSnackBar("Failed to fetch genres.", Colors.red);
      }
    } catch (e) {
      showSnackBar("Error fetching genres: $e", Colors.red);
    }
  }

  void loadUserPreferredGenres() {
    if (!widget.isNewUser) {
      var box = Hive.box('userBox');
      List<String> storedGenres =
          List<String>.from(box.get('preferred_genres', defaultValue: []));
      setState(() {
        selectedGenres = storedGenres;
      });
    }
  }

  void toggleGenreSelection(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        selectedGenres.add(genre);
      }
    });
  }

  Future<void> saveGenres() async {
    if (token == null) {
      showSnackBar("User not authenticated!", Colors.red);
      return;
    }

    try {
      // Use the exact endpoint name from your urls.py
      final endpoint = '${baseUrl}up_user_prefrences/';
      final requestBody = {"preferred_genres": selectedGenres};

      print("Sending request to: $endpoint");
      print("Request body: ${jsonEncode(requestBody)}");
      print("Selected genres: $selectedGenres");

      var response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
        body: jsonEncode(requestBody),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var box = Hive.box('userBox');
        await box.put('preferred_genres', selectedGenres);

        showSnackBar("Genres saved successfully!", Colors.green);

        if (widget.isNewUser) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      } else {
        showSnackBar(
            "Failed to save genres: ${response.statusCode} - ${response.body}",
            Colors.red);
      }
    } catch (e) {
      showSnackBar("Error saving genres: $e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isNewUser ? "Select Your Genres" : "Update Preferences"),
        centerTitle: true,
      ),
      body: allGenres.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.isNewUser
                        ? "Pick your favourite genres!"
                        : "Update your preferences",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: allGenres.map((genre) {
                      return _buildGenreItem(genre);
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor:
                              const Color.fromARGB(255, 152, 72, 178),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: saveGenres,
                        child: Text(
                          widget.isNewUser ? "Continue" : "Save Preferences",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGenreItem(String genre) {
    bool isSelected = selectedGenres.contains(genre);
    return GestureDetector(
      onTap: () => toggleGenreSelection(genre),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Text(
          genre,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
