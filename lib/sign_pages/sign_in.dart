import 'dart:async';
import 'dart:io';

import 'package:bookstore/genre_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:bookstore/base_url.dart';
import 'package:bookstore/sign_pages/verify_token_page.dart';
import 'package:bookstore/home_page/home_page.dart';
import 'package:bookstore/sign_pages/forgotten_pw.dart';
import 'package:bookstore/sign_pages/sign_up.dart';
import 'package:path_provider/path_provider.dart';

Future<String> downloadAndSaveImage(String imageUrl) async {
  try {
    Uri uri = Uri.parse(imageUrl);
    // Get original extension from URL
    String extension = uri.pathSegments.last.split('.').last.toLowerCase();
    // If no valid extension found, default to jpg
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      extension = 'jpg';
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Use app_flutter directory instead of temp
      Directory appDir = await getApplicationDocumentsDirectory();
      String profileImagesDir = '${appDir.path}/profile_images';

      // Create directory if it doesn't exist
      await Directory(profileImagesDir).create(recursive: true);

      // Delete all existing profile images
      await Directory(profileImagesDir)
          .list()
          .where((entity) => entity is File)
          .forEach((entity) => entity.delete());

      // Save new image with correct extension
      String filePath = '$profileImagesDir/current_profile.$extension';
      File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Clean up cache directory
      Directory cacheDir = Directory('${(await getTemporaryDirectory()).path}');
      if (cacheDir.existsSync()) {
        cacheDir
            .listSync(recursive: true)
            .where((entity) =>
                entity.path.endsWith('.jpg') ||
                entity.path.endsWith('.jpeg') ||
                entity.path.endsWith('.png'))
            .forEach((entity) => entity.deleteSync());
      }

      print("Saved new profile image at: $filePath");
      return filePath;
    } else {
      print('Failed to download image: ${response.statusCode}');
      return '';
    }
  } catch (e) {
    print('Error downloading image: $e');
    return '';
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> data = {
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
    };

    const String apiUrl = "${baseUrl}sign_in/";

    try {
      print("Attempting to sign in with URL: $apiUrl");
      print("Request data: ${json.encode(data)}");

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 15)); // Increased timeout

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        await _storage.write(key: 'token', value: responseData['token']);
        await saveUserData(responseData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bienvenue, ${responseData['user']['username']}!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => responseData['user']['has_preferred_genres']
                  ? const HomePage()
                  : const GenreSelectionScreen(
                      isNewUser: true,
                    )),
          (Route<dynamic> route) => false,
        );
      } else {
        String errorMessage =
            responseData['error'] ?? "Une erreur s'est produite.";
        if (errorMessage ==
            "Email not verified. Please verify your email first.") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VerifyTokenPage(
                ispasswordToken: false,
                isFromSignIn: true,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } on SocketException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Pas de connexion internet. Veuillez vérifier votre connexion."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Le serveur ne répond pas. Veuillez réessayer plus tard."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Une erreur s'est produite. Veuillez réessayer."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    var box = Hive.box('userBox');

    await box.put('username', userData['user']['username'] ?? "");
    await box.put('first_name', userData['user']['first_name'] ?? "");
    await box.put('last_name', userData['user']['last_name'] ?? "");
    await box.put('email', userData['user']['email'] ?? "");
    await box.put(
        'phone_number', formatNumberFromBack(userData['user']['phone_number']));

    // Save preferred genres if they exist in the response
    if (userData['user']['preferred_genres'] != null) {
      List<String> preferredGenres = List<String>.from(userData['user']
              ['preferred_genres']
          .map((genre) => genre.toString()));
      await box.put('preferred_genres', preferredGenres);
      print("Saved preferred genres to Hive: $preferredGenres");
    } else {
      // If no preferred genres, initialize with empty list
      await box.put('preferred_genres', []);
      print(
          "No preferred genres found in user data, initialized with empty list");
    }

    String? imageUrl = userData['user']['profile_image'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      String? oldPath = box.get('profile_image');

      if (oldPath != null && oldPath.isNotEmpty && File(oldPath).existsSync()) {
        await File(oldPath).delete();
      }

      String localPath = await downloadAndSaveImage(imageUrl);
      await box.put('profile_image', localPath);
    }
  }

  String formatNumberFromBack(String? numb) {
    if (numb == null || numb.isEmpty) {
      return "";
    } else if (numb.length < 4) {
      return "";
    } else {
      return "0${numb.substring(4)}";
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required String validationMessage,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword,
      keyboardType: isPassword
          ? TextInputType.visiblePassword
          : TextInputType.emailAddress,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: (value) {
        if (!isPassword) {
          FocusScope.of(context).requestFocus(passwordFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      cursorColor: Colors.black,
      style: const TextStyle(fontSize: 17, color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 152, 72, 178), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 17),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 17),
        errorStyle: const TextStyle(fontSize: 14, color: Colors.red),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validationMessage;
        }
        if (!isPassword && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Veuillez entrer un email valide.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Image(
          height: 100,
          width: 100,
          image: AssetImage('assets/icons/logo.png'),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: KeyboardDismisser(
          gestures: const [GestureType.onTap, GestureType.onVerticalDragDown],
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authentification',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connectez-vous pour profiter de l\'intégralité de nos services',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      label: "Email",
                      hint: "Saisissez votre Email",
                      validationMessage: "L'email est obligatoire.",
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      label: "Mot de passe",
                      hint: "Saisissez votre mot de passe",
                      validationMessage: "Le mot de passe est obligatoire.",
                      isPassword: true,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 152, 72, 178),
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Connexion',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text("Pas encore inscrit ? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Créer un compte",
                            style: TextStyle(
                                color: Color.fromARGB(255, 152, 72, 178)),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text("Mot de passe oublié ? "),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgottenPwPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Récupérer votre mot de passe",
                            style: TextStyle(
                                color: Color.fromARGB(255, 152, 72, 178)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
