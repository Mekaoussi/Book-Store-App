import 'dart:async';
import 'dart:io';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/sign_pages/verify_token_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class ForgottenPwPage extends StatefulWidget {
  const ForgottenPwPage({super.key});

  @override
  State<ForgottenPwPage> createState() => _ForgottenPwPageState();
}

class _ForgottenPwPageState extends State<ForgottenPwPage> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FocusNode emailFocusNode = FocusNode();

  Future<void> _requestPasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}request_pw_reset/'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': emailController.text,
            }),
          )
          .timeout(const Duration(seconds: 10)); // Add a timeout of 10 seconds

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Instructions de récupération envoyées à votre email.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerifyTokenPage(ispasswordToken: true),
          ),
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorResponse['error'] ?? "Erreur serveur"),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      focusNode: emailFocusNode,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.emailAddress,
      onFieldSubmitted: (value) {
        FocusScope.of(context).unfocus();
      },
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
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 237, 56, 43), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 237, 56, 43), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        labelText: 'Email',
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 100, 100, 100),
          fontSize: 17,
        ),
        hintText: 'Saisissez votre Email',
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 160, 154, 156),
          fontSize: 17,
        ),
        errorStyle: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(255, 237, 56, 43),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'L\'email est obligatoire.';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Veuillez entrer un email valide.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(250, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(250, 250, 250, 250),
        title: const Text(
          "Sign in",
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
                      'Réinitialiser votre mot de passe',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Entrez votre email pour recevoir les instructions de réinitialisation.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    _buildEmailField(),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _requestPasswordReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 152, 72, 178),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Récupérer mon mot de passe',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
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

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }
}
