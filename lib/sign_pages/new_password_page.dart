import 'dart:async';
import 'dart:io';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/sign_pages/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final _storage = const FlutterSecureStorage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> clearPasswordToken() async {
    try {
      await _storage.delete(key: 'short_password_token');
      print('Password token cleared successfully.');
    } catch (e) {
      print('Error clearing password token: $e');
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    String? storedToken = await _storage.read(key: 'short_password_token');

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}reset_pw/'),
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'new_password': newPasswordController.text,
              'token': storedToken,
            }),
          )
          .timeout(const Duration(seconds: 10)); // Add a timeout of 10 seconds

      if (!mounted) return;

      if (response.statusCode == 200) {
        await clearPasswordToken();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Mot de passe mis à jour avec succès."),
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
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        final errorResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorResponse['message'] ?? "Erreur serveur"),
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
      // Handle no internet or server offline
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
      // Handle timeout
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
      // Handle other exceptions
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

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPasswordVisible = false,
    required VoidCallback toggleVisibility,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      focusNode: focusNode,
      textInputAction:
          nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onFieldSubmitted: (value) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
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
              color: Color.fromARGB(255, 152, 72, 178), width: 2),
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
        labelText: label,
        labelStyle: const TextStyle(
          color: Color.fromARGB(255, 100, 100, 100),
          fontSize: 17,
        ),
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 160, 154, 156),
          fontSize: 17,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: toggleVisibility,
        ),
        errorStyle: const TextStyle(
          fontSize: 14,
          color: Color.fromARGB(255, 237, 56, 43),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(250, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(250, 250, 250, 250),
        title: const Text(
          "Nouveau mot de passe",
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
                      'Définir un nouveau mot de passe',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Veuillez saisir un mot de passe sécurisé et le confirmer.',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    _buildPasswordField(
                      label: 'Nouveau mot de passe',
                      hint: 'Entrez votre nouveau mot de passe',
                      controller: newPasswordController,
                      isPasswordVisible: _isNewPasswordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                      focusNode: newPasswordFocusNode,
                      nextFocusNode: confirmPasswordFocusNode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Le mot de passe est obligatoire.";
                        }
                        if (value.length < 8) {
                          return "Le mot de passe doit contenir au moins 8 caractères.";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      label: 'Confirmer le mot de passe',
                      hint: 'Confirmez votre mot de passe',
                      controller: confirmPasswordController,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      toggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                      focusNode: confirmPasswordFocusNode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "La confirmation du mot de passe est obligatoire.";
                        }
                        if (value != newPasswordController.text) {
                          return "Les mots de passe ne correspondent pas.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitNewPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 152, 72, 178),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Soumettre",
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
