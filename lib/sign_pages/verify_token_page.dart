import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/home_page/home_page.dart';
import 'package:bookstore/sign_pages/new_password_page.dart';
import 'package:bookstore/sign_pages/sign_in.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class VerifyTokenPage extends StatefulWidget {
  final bool ispasswordToken;
  final bool? isFromSignIn;
  const VerifyTokenPage(
      {super.key, required this.ispasswordToken, this.isFromSignIn});

  @override
  State<VerifyTokenPage> createState() => _VerifyTokenPageState();
}

class _VerifyTokenPageState extends State<VerifyTokenPage> {
  TextEditingController tokenController = TextEditingController();
  FlutterSecureStorage? _storage;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _verifyToken() async {
    if (!_formKey.currentState!.validate()) return;

    String endpoint =
        widget.ispasswordToken == true ? 'validate_pw_token' : 'validate_email';

    final String token = tokenController.text.trim();
    final String apiUrl = "$baseUrl$endpoint/";

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"token": token}),
          )
          .timeout(const Duration(seconds: 7));

      if (widget.ispasswordToken) {
        _storage = const FlutterSecureStorage();
      }

      if (response.statusCode == 200) {
        await _storage?.write(
            key: 'short_password_token', value: tokenController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Vérification réussie !"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        widget.ispasswordToken == false && widget.isFromSignIn == true
            ? Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
              )
            : widget.ispasswordToken == false
                ? Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                    (Route<dynamic> route) => false,
                  )
                : Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NewPasswordPage()),
                  );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Le Code est invalide ou expiré."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(250, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(250, 250, 250, 250),
        title: const Text(
          "Vérifier le Code",
          style: TextStyle(fontWeight: FontWeight.bold),
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
                      'Entrez votre Code',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Un Code vous a été envoyé par email. Veuillez le saisir ci-dessous pour vérifier votre compte.",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: tokenController,
                      cursorColor: const Color.fromARGB(255, 1, 1, 1),
                      style: const TextStyle(
                        color: Color.fromARGB(255, 1, 1, 1),
                        fontSize: 17,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 152, 72, 178),
                              width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color.fromRGBO(224, 224, 224, 1),
                              width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color.fromRGBO(255, 9, 9, 1), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color.fromRGBO(255, 9, 9, 1), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: 'Code',
                        labelStyle: const TextStyle(
                          color: Color.fromARGB(255, 100, 100, 100),
                          fontSize: 17,
                        ),
                        hintText: 'Enter your Code',
                        hintStyle: const TextStyle(
                          color: Color.fromARGB(255, 160, 154, 156),
                          fontSize: 17,
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 14,
                          color: Color.fromRGBO(255, 9, 9, 1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Code is required.";
                        }

                        if (value.trim().length < 7) {
                          return 'Code is too short';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _verifyToken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 152, 72, 178),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Vérifier",
                          style: TextStyle(
                              fontSize: 18,
                              color: Color.fromARGB(255, 255, 255, 255)),
                        ),
                      ),
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
}
