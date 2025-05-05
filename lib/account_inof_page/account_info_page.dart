import 'dart:async';
import 'dart:convert';

import 'package:bookstore/base_url.dart';
import 'package:bookstore/genre_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  late Box userBox;
  bool isEditing = false;
  final storage = const FlutterSecureStorage();
  bool isLoading = false;
  File? _pickedImageFile;
  File? _savedImageFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userBox = Hive.box('userBox');
    _loadUserData();
  }

  void _loadUserData() {
    lastNameController.text = userBox.get('last_name', defaultValue: "");
    firstNameController.text = userBox.get('first_name', defaultValue: "");
    usernameController.text = userBox.get('username', defaultValue: "");
    emailController.text = userBox.get('email', defaultValue: "");
    phoneController.text = userBox.get('phone_number', defaultValue: "");

    String? savedProfileImage =
        userBox.get('profile_image', defaultValue: null);
    if (savedProfileImage != null && savedProfileImage.isNotEmpty) {
      setState(() {
        _savedImageFile = File(savedProfileImage);
        // Use saved image as the current image if no picked image
        _pickedImageFile ??= _savedImageFile;
      });
    }
  }

  void _resetUserData() {
    lastNameController.text = userBox.get('last_name', defaultValue: "");
    firstNameController.text = userBox.get('first_name', defaultValue: "");
    usernameController.text = userBox.get('username', defaultValue: "");
    emailController.text = userBox.get('email', defaultValue: "");
    phoneController.text = userBox.get('phone_number', defaultValue: "");

    String? savedProfileImage =
        userBox.get('profile_image', defaultValue: null);
    setState(() {
      // Reset to saved image from Hive
      _pickedImageFile =
          savedProfileImage != null && savedProfileImage.isNotEmpty
              ? File(savedProfileImage)
              : null;
      _savedImageFile = _pickedImageFile;
      isEditing = false;
    });
  }

  @override
  void dispose() {
    lastNameController.dispose();
    firstNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String formatPhoneNumber(String phone) {
    if (phone.isEmpty) {
      return phone;
    }
    return "+213${phone.substring(1)}";
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

  Future<void> clearCache() async {
    try {
      // Clear application cache
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint('Error deleting cache entity: $e');
          }
        }
      }

      // Clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${baseUrl}update_profile/'),
      );

      request.headers.addAll({
        'Authorization': 'Token $token',
        'Content-Type': 'multipart/form-data',
      });

      request.fields['last_name'] = lastNameController.text;
      request.fields['first_name'] = firstNameController.text;
      request.fields['username'] = usernameController.text;
      request.fields['email'] = emailController.text;
      request.fields['phone_number'] =
          formatPhoneNumber(phoneController.text.trim());

      if (_pickedImageFile != null) {
        String oldImagePath = userBox.get('profile_image', defaultValue: '');
        if (_pickedImageFile!.path != oldImagePath) {
          request.files.add(await http.MultipartFile.fromPath(
            'profile_image',
            _pickedImageFile!.path,
          ));
        }
      }

      var response = await request.send().timeout(const Duration(seconds: 7));
      var responseBody = await response.stream.bytesToString();
      var responseData = json.decode(responseBody);

      if (!mounted) return;

      if (response.statusCode == 200) {
        userBox.put('last_name', lastNameController.text);
        userBox.put('first_name', firstNameController.text);
        userBox.put('username', usernameController.text);
        userBox.put('email', emailController.text);
        userBox.put('phone_number', phoneController.text.trim());

        if (_pickedImageFile != null) {
          String oldImagePath = userBox.get('profile_image', defaultValue: '');

          if (_pickedImageFile!.path != oldImagePath) {
            // Delete old image file if it exists
            if (oldImagePath.isNotEmpty && File(oldImagePath).existsSync()) {
              await File(oldImagePath).delete();
            }

            // Get file extension and validate it
            String extension =
                _pickedImageFile!.path.split('.').last.toLowerCase();
            if (!['jpg', 'jpeg', 'png'].contains(extension)) {
              extension = 'jpg';
            }

            // Create directory for profile images
            Directory appDir = await getApplicationDocumentsDirectory();
            String profileImagesDir = '${appDir.path}/profile_images';
            await Directory(profileImagesDir).create(recursive: true);

            // Clear any existing profile images
            final dir = Directory(profileImagesDir);
            if (await dir.exists()) {
              await for (var entity in dir.list()) {
                if (entity is File) {
                  await entity.delete();
                }
              }
            }

            // Create new path and copy file
            String newPath = '$profileImagesDir/current_profile.$extension';
            await _pickedImageFile!.copy(newPath);

            // Update Hive storage
            await userBox.put('profile_image', newPath);

            // Clear cache to ensure fresh image loading
            await clearCache();

            // Create new File objects to ensure they point to the new file
            File newImageFile = File(newPath);

            // Update state with new file references
            setState(() {
              _pickedImageFile = newImageFile;
              _savedImageFile = newImageFile;
            });
          }
        }

        showSnackBar("Profil mis à jour avec succès !", Colors.green);
        setState(() {
          isEditing = false;
        });

        // Force a complete rebuild of the widget
        forceRebuild();
      } else {
        showSnackBar(
            "Échec de la mise à jour du profil: ${responseData['error'] ?? 'Unknown error'}",
            Colors.red);
      }
    } on SocketException {
      showSnackBar(
          "Pas de connexion Internet. Veuillez vérifier votre connexion.",
          Colors.red);
    } on TimeoutException {
      showSnackBar("Le serveur ne répond pas. Veuillez réessayer plus tard.",
          Colors.red);
    } catch (e) {
      showSnackBar(
          "Une erreur s'est produite. Veuillez réessayer.", Colors.red);
      print("Error updating profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      setState(() {
        _pickedImageFile = File(image.path);
      });
    }
  }

  Widget buildProfileImage() {
    // Force reload the image path from Hive every time this widget builds
    String? savedImagePath = userBox.get('profile_image', defaultValue: null);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return GestureDetector(
      onTap: isEditing ? pickImage : null,
      child: Stack(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 154, 49, 247),
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                key: ValueKey('profile-$timestamp'),
                radius: 80,
                // Use FutureBuilder to load the image asynchronously
                child: ClipOval(
                  child: _pickedImageFile != null && isEditing
                      ? Image.file(
                          _pickedImageFile!,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          // Add cache-busting query parameter
                          cacheWidth: 300,
                          key: ValueKey('picked-$timestamp'),
                        )
                      : savedImagePath != null && savedImagePath.isNotEmpty
                          ? Image.file(
                              File(savedImagePath),
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              // Add cache-busting query parameter
                              cacheWidth: 300,
                              key: ValueKey('saved-$timestamp'),
                            )
                          : Image.asset(
                              'assets/images/me.jpg',
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                ),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 154, 49, 247),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void forceRebuild() async {
    if (mounted) {
      // Clear Flutter's image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Reset the picked image
      setState(() {
        _pickedImageFile = null;
      });

      // Reload the image path from Hive
      String? savedImagePath = userBox.get('profile_image', defaultValue: null);

      if (savedImagePath != null && savedImagePath.isNotEmpty) {
        // Create a new File instance to force Flutter to reload the image
        File imageFile = File(savedImagePath);

        // Verify the file exists
        if (await imageFile.exists()) {
          // Schedule multiple rebuilds to ensure the UI updates
          for (int i = 0; i < 3; i++) {
            await Future.delayed(Duration(milliseconds: 300 * i));
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEditing) {
                updateProfile();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _resetUserData,
            ),
        ],
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        centerTitle: true,
        title: const Text("Mon Compte"),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 154, 49, 247)))
          : SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    buildProfileImage(),
                    const SizedBox(height: 20),
                    accountInfoField("Nom", lastNameController, !isEditing),
                    accountInfoField("Prenom", firstNameController, !isEditing),
                    accountInfoField(
                        "Nom d'utilisateur", usernameController, !isEditing),
                    accountInfoField("Email", emailController, !isEditing),
                    accountInfoField(
                        "N° Telephone", phoneController, !isEditing),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const GenreSelectionScreen(isNewUser: false),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 154, 49, 247),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Edit your prefrences'),
                      ),
                    ),
                    if (isEditing)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 154, 49, 247),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

Widget accountInfoField(
    String label, TextEditingController controller, bool readOnly) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 45,
          width: double.infinity,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            cursorColor: const Color.fromARGB(255, 154, 49, 247),
            style: const TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? const Color.fromARGB(255, 230, 230, 230)
                  : Colors.white,
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 154, 49, 247),
                ),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
