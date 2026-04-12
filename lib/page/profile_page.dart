import 'dart:io';
import 'package:chat_apps/page/login_page.dart';
import 'package:chat_apps/provider/auth_provider.dart';
import 'package:chat_apps/provider/cache_provider.dart';
import 'package:chat_apps/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);

    user.whenData((userData) {
      if (userData != null) {
        _displayNameController.text = userData.displayName;
        _bioController.text = userData.bio ?? '';
        _websiteController.text = userData.website ?? '';
        _phoneNumberController.text = userData.phoneNumber ?? '';

        _profileImageUrl = userData.profilePictureUrl;

        print("IMAGE URL: $_profileImageUrl"); // 🔥 DEBUG
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path); // ✅ instant preview
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _profileImageUrl;

      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();

        imageUrl = await uploadProfilePictureWidget(
          ref,
          _selectedImage!.path,
          bytes,
        );
      }

      await updateUserProfileWidget(
        ref,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        profilePictureUrl: imageUrl,
      );

      setState(() {
        _profileImageUrl = imageUrl;
        _selectedImage = null;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logOut,
          ),
        ],
      ),

      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),

        error: (e, _) => Center(child: Text("Error: $e")),

        data: (userData) {
          if (userData == null) {
            return const Center(child: Text("User not found"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ✅ PROFILE IMAGE FIXED
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Stack(
                      children: [
                        // In your build method, inside the data: (userData) block:
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[600],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                                    as ImageProvider // 1. local picked image
                              : (userData.profilePictureUrl !=
                                        null && // 2. ✅ from provider, not stale state
                                    userData.profilePictureUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(
                                  userData.profilePictureUrl!,
                                )
                              : null,
                          child:
                              (_selectedImage == null &&
                                  (userData.profilePictureUrl == null ||
                                      userData.profilePictureUrl!.isEmpty))
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildReadOnlyField(
                    title: 'Username',
                    value: userData.username,
                  ),

                  const SizedBox(height: 16),

                  _buildReadOnlyField(title: 'Email', value: userData.email),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    controller: _displayNameController,
                    title: 'Display Name',
                    hintText: 'Enter your display name',
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    controller: _bioController,
                    title: 'Bio',
                    hintText: 'Tell about yourself',
                    enabled: _isEditing,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    controller: _websiteController,
                    title: 'Website',
                    hintText: 'yourwebsite.com',
                    enabled: _isEditing,
                  ),

                  const SizedBox(height: 16),

                  _buildEditableField(
                    controller: _phoneNumberController,
                    title: 'Phone Number',
                    hintText: '+123456789',
                    enabled: _isEditing,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyField({required String title, required String value}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String title,
    required String hintText,
    required bool enabled,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: title, hintText: hintText),
    );
  }

  Future<void> _logOut() async {
    final prefs = ref.read(sharePrefProvider);
    await prefs.clear();
    await ref.read(authProvider.notifier).signOut();
    ref.invalidate(currentUserProvider);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}
