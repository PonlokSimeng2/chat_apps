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
  File? _selectedImage;
  bool _isSaving = false;
  bool _notificationsEnabled = true;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _selectedImage = file; // instant preview
      _isSaving = true;
    });

    try {
      final bytes = await file.readAsBytes();
      final imageUrl = await uploadProfilePictureWidget(ref, file.path, bytes);

      final current = ref.read(currentUserProvider).value;

      await updateUserProfileWidget(
        ref,
        username: current?.username ?? '',
        bio: current?.bio ?? '',
        phoneNumber: current?.phoneNumber ?? '',
        profilePictureUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editTextField({
    required String title,
    required String initialValue,
    required Future<void> Function(String newValue) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text('Edit $title', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != initialValue) {
      setState(() => _isSaving = true);
      try {
        await onSave(result);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title updated')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _logOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (userData) {
          if (userData == null) {
            return const Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ── Avatar with edit pencil ─────────────────────
                GestureDetector(
                  onTap: _isSaving ? null : _pickAndUploadImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[600],
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!) as ImageProvider
                            : (userData.profilePictureUrl != null &&
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
                      if (_isSaving)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black45,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0B0F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Username (big title, tappable to edit) ─────
                GestureDetector(
                  onTap: () => _editTextField(
                    title: 'Username',
                    initialValue: userData.username,
                    onSave: (value) => updateUserProfileWidget(
                      ref,
                      username: value,
                      bio: userData.bio ?? '',
                      phoneNumber: userData.phoneNumber ?? '',
                      profilePictureUrl: userData.profilePictureUrl,
                    ),
                  ),
                  child: Text(
                    userData.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Status / bio ─────────────────────
                GestureDetector(
                  onTap: () => _editTextField(
                    title: 'Status',
                    initialValue: userData.bio ?? '',
                    onSave: (value) => updateUserProfileWidget(
                      ref,
                      username: userData.username,
                      bio: value,
                      phoneNumber: userData.phoneNumber ?? '',
                      profilePictureUrl: userData.profilePictureUrl,
                    ),
                  ),
                  child: Text(
                    (userData.bio == null || userData.bio!.isEmpty)
                        ? 'Available'
                        : userData.bio!,
                    style: const TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 28),

                _buildSectionHeader('Account'),
                const SizedBox(height: 12),

                _buildInfoRow(
                  label: 'Username',
                  value: '@${userData.username}',
                ),
                const SizedBox(height: 10),

                // ── Phone ─────────────────────
                _buildInfoRow(
                  label: 'Phone',
                  value:
                      (userData.phoneNumber == null ||
                          userData.phoneNumber!.isEmpty)
                      ? 'Add phone number'
                      : userData.phoneNumber!,
                  onTap: () => _editTextField(
                    title: 'Phone Number',
                    initialValue: userData.phoneNumber ?? '',
                    onSave: (value) => updateUserProfileWidget(
                      ref,
                      username: userData.username,
                      bio: userData.bio ?? '',
                      phoneNumber: value,
                      profilePictureUrl: userData.profilePictureUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow(label: 'Email', value: userData.email),

                const SizedBox(height: 28),

                _buildSectionHeader('Settings'),
                const SizedBox(height: 12),

                _buildSwitchRow(
                  label: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                const SizedBox(height: 10),
                _buildChevronRow(
                  label: 'Privacy',
                  onTap: () {
                    // TODO: navigate to privacy settings
                  },
                ),
                const SizedBox(height: 10),
                _buildChevronRow(
                  label: 'Appearance',
                  onTap: () {
                    // TODO: navigate to appearance settings
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildChevronRow({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
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
