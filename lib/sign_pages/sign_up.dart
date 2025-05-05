import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/sign_pages/verify_token_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:keyboard_dismisser/keyboard_dismisser.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController lastNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passWordController = TextEditingController();
  TextEditingController confPassWordController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();
  FocusNode userNameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode confPasswordFocusNode = FocusNode();
  FocusNode phoneNumberFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfPasswordVisible = false;

  Widget _buildStylishField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required bool isConfPasswordField,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: controller == phoneNumberController
                ? TextInputType.number
                : controller == emailController
                    ? TextInputType.emailAddress
                    : keyboardType,
            obscureText: isPassword &&
                !((isConfPasswordField)
                    ? _isConfPasswordVisible
                    : _isPasswordVisible),
            focusNode: focusNode,
            textInputAction: nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
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
                    color: Color.fromRGBO(255, 9, 9, 1),
                    width: 2), // Error border style
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                    color: Color.fromRGBO(255, 9, 9, 1),
                    width: 2), // Focused error border
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
              suffixIcon: isPassword || isConfPasswordField
                  ? IconButton(
                      icon: Icon(
                        (isConfPasswordField
                                ? _isConfPasswordVisible
                                : _isPasswordVisible)
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConfPasswordField) {
                            _isConfPasswordVisible = !_isConfPasswordVisible;
                          } else {
                            _isPasswordVisible = !_isPasswordVisible;
                          }
                        });
                      },
                    )
                  : null,
              errorStyle: const TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(255, 9, 9, 1),
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.trim().isEmpty)) {
                return "$label est obligatoire.";
              }
              if (isPassword && value != null && value.length < 8) {
                return "Le mot de passe doit contenir au moins 8 caractères.";
              }
              if (isConfPasswordField && value != passWordController.text) {
                return "Les mots de passe ne correspondent pas.";
              }
              if (controller == emailController &&
                  value != null &&
                  value.isNotEmpty) {
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return "Veuillez entrer un email valide.";
                }
              }
              return null;
            },
          ),
        ),
        if (isRequired)
          const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              "*",
              style: TextStyle(
                color: Color.fromARGB(255, 152, 72, 178),
                fontSize: 25,
              ),
            ),
          ),
      ],
    );
  }

  String formatPhoneNumber(String string) {
    if (string.isEmpty) {
      return string;
    }
    return "+213${string.substring(1)}";
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> data = {
      "last_name": lastNameController.text.trim(),
      "first_name": firstNameController.text.trim(),
      "username": userNameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passWordController.text.trim(),
      "phone_number": formatPhoneNumber(phoneNumberController.text.trim()),
    };

    const String apiUrl = "${baseUrl}sign_up/";

    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {"Content-Type": "application/json"},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 7));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                "Inscription réussie ! Veuillez vérifier votre email."),
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
            builder: (context) => const VerifyTokenPage(
              ispasswordToken: false,
            ),
          ),
        );
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        String errorMessage = '';
        if (responseData.containsKey('error')) {
          responseData['error'].forEach((field, messages) {
            for (var msg in messages) {
              errorMessage += '$field: $msg\n';
            }
          });
        } else {
          errorMessage = "Une erreur s'est produite.";
        }

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
          "Sign In",
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
                      'Créer votre compte',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Les champs avec le symbole ',
                            style: TextStyle(color: Colors.black, fontSize: 19),
                          ),
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: Color.fromARGB(255, 152, 72, 178),
                              fontSize: 25,
                            ),
                          ),
                          TextSpan(
                            text: ' sont obligatoires.',
                            style: TextStyle(color: Colors.black, fontSize: 19),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildStylishField(
                      label: 'Nom',
                      hint: 'Entrez votre nom',
                      controller: lastNameController,
                      isRequired: false,
                      focusNode: lastNameFocusNode,
                      nextFocusNode: firstNameFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Prénom',
                      hint: 'Entrez votre prénom',
                      controller: firstNameController,
                      isRequired: false,
                      focusNode: firstNameFocusNode,
                      nextFocusNode: userNameFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Nom d\'utilisateur',
                      hint: 'Entrez un nom d\'utilisateur',
                      controller: userNameController,
                      isRequired: true,
                      focusNode: userNameFocusNode,
                      nextFocusNode: emailFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Email',
                      hint: 'Entrez votre email',
                      controller: emailController,
                      isRequired: true,
                      focusNode: emailFocusNode,
                      nextFocusNode: passwordFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Mot de passe',
                      hint: 'Entrez votre mot de passe',
                      controller: passWordController,
                      isRequired: true,
                      isPassword: true,
                      focusNode: passwordFocusNode,
                      nextFocusNode: confPasswordFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Confirmer le mot de passe',
                      hint: 'Confirmez votre mot de passe',
                      controller: confPassWordController,
                      isRequired: true,
                      isPassword: true,
                      focusNode: confPasswordFocusNode,
                      isConfPasswordField: true,
                      nextFocusNode: phoneNumberFocusNode,
                    ),
                    const SizedBox(height: 20),
                    _buildStylishField(
                      label: 'Numéro de téléphone',
                      hint: 'Entrez votre numéro de téléphone',
                      controller: phoneNumberController,
                      isRequired: false,
                      focusNode: phoneNumberFocusNode,
                      isConfPasswordField: false,
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 152, 72, 178),
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "S'inscrire",
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
