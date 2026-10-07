import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<UserProvider>().loadUser(uid: uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserProvider, UserModel?>((p) => p.user);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PersonalInformationTopBar(),
                  if (user == null) ...[
                    const SizedBox(height: 32),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 32),
                  ] else ...[
                    ProfilePhotoCard(
                      user: user,
                      onUploadTap: () => handleUploadPhoto(context, user),
                    ),
                    UpdateBasicInformation(user: user),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PersonalInformationTopBar extends StatelessWidget {
  const PersonalInformationTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoBack(onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 16),
          Text(
            'Personal Information',
            style: TextStyle(
              color: colors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Update your details',
            style: TextStyle(
              color: colors.surface,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePhotoCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUploadTap;

  const ProfilePhotoCard({
    super.key,
    required this.user,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasPhoto = user.photoUrl.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.inversePrimary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE2E2E2),
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl) : null,
                child: !hasPhoto
                    ? const Icon(
                        Icons.person,
                        size: 38,
                        color: Color.fromARGB(94, 65, 0, 149),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: onUploadTap,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.camera,
                        size: 13,
                        color: colors.inversePrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your profile picture\nMax file size: 5MB',
                  style: TextStyle(
                    color: colors.surface,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateBasicInformation extends StatefulWidget {
  final UserModel user;

  const UpdateBasicInformation({super.key, required this.user});

  @override
  State<UpdateBasicInformation> createState() => _UpdateBasicInformationState();
}

class _UpdateBasicInformationState extends State<UpdateBasicInformation> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(BuildContext context, String hintText) {
    final focusColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF5B5B5B)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(context, label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
            validator: validator,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration(context, hint),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Please correct the errors in the form.',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<UserProvider>().updateProfile(
        name: _nameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Changes saved successfully!',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Failed to save changes: $e',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).textTheme.headlineLarge?.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: bg,
      ),
      child: Column(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                _buildTextField(
                  context: context,
                  label: 'Full Name',
                  controller: _nameController,
                  hint: 'Full name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  context: context,
                  label: 'First Name',
                  controller: _firstNameController,
                  hint: 'First name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  context: context,
                  label: 'Last Name',
                  controller: _lastNameController,
                  hint: 'Last name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  context: context,
                  label: 'Email',
                  controller: _emailController,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Please enter your email';
                    if (!RegExp(
                      r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(v)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  context: context,
                  label: 'Phone Number',
                  controller: _phoneController,
                  hint: 'Phone number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: bg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isLoading
                    ? LoadingButton(
                        height: 35,
                        width: 35,
                        scale: 1,
                        containerHeight: 42,
                        containerWidth: 145,
                      )
                    : RegularButton(
                        onPressed: _save,
                        borderRadius: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        textWidget: CustomText(
                          text: 'Save Changes',
                          textColor: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.color,
                          textSize: 14,
                          textWeight: FontWeight.bold,
                        ),
                      ),
                RegularButton(
                  onPressed: () => Navigator.of(context).pop(),
                  borderRadius: 8,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 34,
                  ),
                  textWidget: GradientText(
                    text: 'Cancel',
                    gradient: const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Color.fromARGB(255, 73, 64, 241),
                        Color.fromARGB(255, 149, 60, 237),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> handleUploadPhoto(BuildContext context, UserModel user) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) return;

  final file = File(pickedFile.path);
  final storageRef = FirebaseStorage.instance.ref().child(
    'user_profile_photos/${user.uid}.jpg',
  );

  try {
    final uploadTask = storageRef.putFile(file);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(uploadTask: uploadTask),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updatedUser = user.copyWith(
      photoUrl: downloadUrl,
      updatedAt: DateTime.now(),
    );

    await Provider.of<UserProvider>(
      context,
      listen: false,
    ).setUser(updatedUser);

    if (context.mounted) Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated successfully')),
    );
  } catch (e) {
    debugPrint('Upload failed: $e');

    if (context.mounted) Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
  }
}

class UploadProgressDialog extends StatelessWidget {
  final UploadTask uploadTask;

  const UploadProgressDialog({super.key, required this.uploadTask});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<TaskSnapshot>(
          stream: uploadTask.snapshotEvents,
          builder: (context, snapshot) {
            double progress = 0;
            if (snapshot.hasData) {
              final snap = snapshot.data!;
              progress = snap.totalBytes == 0
                  ? 0
                  : snap.bytesTransferred / snap.totalBytes;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Uploading photo...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
