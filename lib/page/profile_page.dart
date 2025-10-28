import 'dart:io';
import 'package:chat_app/page/login_page.dart';
import 'package:chat_app/provider/auth_provider.dart';
import 'package:chat_app/provider/cache_provider.dart';
import 'package:chat_app/provider/user_provider.dart';
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

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
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
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      try {
        setState(() => _isLoading = true);
        final imageUrl = await uploadProfilePictureWidget(ref, pickedFile.path, bytes);
        setState(() {
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await updateUserProfileWidget(
        ref,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        profilePictureUrl: _profileImageUrl,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
            onPressed: _isLoading ? null : () {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Profile Picture
                    GestureDetector(
                      onTap: _isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[600],
                            backgroundImage: _profileImageUrl != null
                                ? CachedNetworkImageProvider(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
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
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // User Info
                    user.when(
                      data: (userData) {
                        if (userData == null) return const Text('User not found');
                        return Column(
                          children: [
                            // Username (read-only)
                            _buildReadOnlyField(
                              title: 'Username',
                              value: userData.username,
                            ),

                            const SizedBox(height: 16),

                            // Email (read-only)
                            _buildReadOnlyField(
                              title: 'Email',
                              value: userData.email,
                            ),

                            const SizedBox(height: 16),

                            // Display Name (editable)
                            _buildEditableField(
                              controller: _displayNameController,
                              title: 'Display Name',
                              hintText: 'Enter your display name',
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Display name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Bio (editable)
                            _buildEditableField(
                              controller: _bioController,
                              title: 'Bio',
                              hintText: 'Tell us about yourself',
                              enabled: _isEditing,
                              maxLines: 3,
                            ),

                            const SizedBox(height: 16),

                            // Website (editable)
                            _buildEditableField(
                              controller: _websiteController,
                              title: 'Website',
                              hintText: 'yourwebsite.com',
                              enabled: _isEditing,
                              keyboardType: TextInputType.url,
                            ),

                            const SizedBox(height: 16),

                            // Phone Number (editable)
                            _buildEditableField(
                              controller: _phoneNumberController,
                              title: 'Phone Number',
                              hintText: '+1 234 567 8900',
                              enabled: _isEditing,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        );
                      },
                      error: (error, stack) => Center(child: Text('Error: $error')),
                      loading: () => const Center(child: CircularProgressIndicator()),
                    ),

                    const SizedBox(height: 30),

                    // Action Buttons
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "Save Changes",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () {
                                setState(() => _isEditing = false);
                                _loadUserData(); // Reset to original values
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField({
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String title,
    required String hintText,
    required bool enabled,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: enabled ? const Color(0xFF2D2D2D) : Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: enabled ? Colors.grey[600]! : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Future<void> _logOut() async {
    final prefs = ref.read(sharePrefProvider);
    await prefs.clear();
    await ref.read(authProvider.notifier).signOut();
    ref.invalidate(currentUserProvider);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
