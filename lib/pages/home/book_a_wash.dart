import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class PersonalInformation extends StatefulWidget {
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation> {
  UserModel? user;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final provider = Provider.of<UserProvider>(context, listen: false);
    provider.loadUser(uid: uid).then((_) {
      setState(() {
        user = provider.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          // Background gradient + animation (outside scroll)
          Positioned.fill(
            child: Stack(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Lottie.asset(
                    'assets/animations/background_animation_light.json',
                    fit: BoxFit.cover,
                    frameRate: FrameRate(30), // Optimized frame rate
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: const Color.fromARGB(140, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PersonalInformationTopBar(),
                  ProfilePhotoCard(
                    user: user!,
                    onUploadTap: () => handleUploadPhoto(context, user!),
                  ),
                  UpdateBasicInformation(user: user!),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalInformationTopBar extends StatelessWidget {
  const PersonalInformationTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Personal Information',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Update your details',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
                    textSize: TextSizes.subtitle2,
                  ),
                ],
              ),
              GoBack(
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
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
    required this.onUploadTap,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = user.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.headlineLarge?.color,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color.fromARGB(255, 226, 226, 226),
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
                child: !hasPhoto
                    ? const Icon(
                        Icons.person,
                        size: 40,
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
                    child: const Center(
                      child: Icon(
                        FontAwesomeIcons.camera,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                'Update your profile picture\nMax file size: 5MB',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
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

  late TextEditingController _name;
  late TextEditingController _emailAddress;
  late TextEditingController _phoneNumber;
  late TextEditingController _address;
  late TextEditingController _dateOfBirth;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _name = TextEditingController(text: widget.user.name);
    _emailAddress = TextEditingController(text: widget.user.email);
    _phoneNumber = TextEditingController(text: widget.user.phoneNumber);
    _address = TextEditingController(text: widget.user.address);
    _dateOfBirth = TextEditingController(text: widget.user.dateOfBirth);
  }

  @override
  void dispose() {
    _name.dispose();
    _emailAddress.dispose();
    _phoneNumber.dispose();
    _address.dispose();
    _dateOfBirth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Theme.of(context).textTheme.headlineLarge?.color,
      ),

      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "name",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: _name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    // Moved generic border to the top to allow specific borders to override
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    hintText: 'name',
                    hintStyle: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      gapPadding: 10,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Email Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: _emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'field must not be empty';
                    }
                    // CORRECTED REGEX: Removed the backslash before $
                    else if (!RegExp(
                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    // Moved generic border to the top to allow specific borders to override
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    hintText: 'email address',
                    hintStyle: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      gapPadding: 10,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm Password
                Text(
                  "Phone Number",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: _phoneNumber,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    // Moved generic border to the top to allow specific borders to override
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    hintText: 'phone number',
                    hintStyle: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      gapPadding: 10,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm Password
                Text(
                  "Address",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: _address,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    // Moved generic border to the top to allow specific borders to override
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    hintText: 'Address',
                    hintStyle: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      gapPadding: 10,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Confirm Password
                Text(
                  "Date of Birth",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: _dateOfBirth,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your DOB';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    // Moved generic border to the top to allow specific borders to override
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    hintText: 'Date of birth',
                    hintStyle: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      gapPadding: 10,
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Theme.of(context).textTheme.headlineLarge?.color,
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isLoading
                    ? LoadingButton(
                        height: 35,
                        width: 35,
                        scale: 1,
                        containerHeight: 40,
                        containerWidth: 135,
                      )
                    : RegularButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // fixed typo
                            final name = _name.text.trim();
                            final emailAddress = _emailAddress.text.trim();
                            final phoneNumber = _phoneNumber.text.trim();
                            final address = _address.text.trim();
                            final dateOfBirth = _dateOfBirth.text.trim();

                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              await saveChanges(
                                context: context,
                                oldUser: widget.user, // pass full user model
                                name: name,
                                emailAddress: emailAddress,
                                phoneNumber: phoneNumber,
                                address: address,
                                dateOfBirth: dateOfBirth,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: CustomText(
                                        text: 'Changes saved successfully!',
                                        textColor: AppColors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Center(
                                      child: CustomText(
                                        text:
                                            'Failed to save new changes: ${e.toString()}',
                                        textColor: AppColors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } else {
                            // show warning if form is invalid
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: CustomText(
                                    text:
                                        'Please correct the errors in the form.',
                                    textColor: AppColors.white,
                                  ),
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: 7,
                        gradient: const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Color.fromARGB(255, 73, 64, 241),
                            Color.fromARGB(255, 149, 60, 237),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        textWidget: CustomText(
                          text: 'Save Changes',
                          textColor: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.color,
                          textSize: TextSizes.bodyText1,
                          textWeight: FontWeight.bold,
                        ),
                      ),
                RegularButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  borderRadius: 7,
                  backgroundColor: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.color,
                  padding: const EdgeInsets.symmetric(
                    /* Theme.of(
                    context,
                  ).textTheme.headlineMedium?.color, */
                    vertical: 10,
                    horizontal: 40,
                  ),
                  textWidget: GradientText(
                    text: 'Cancel..',
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

Future<void> saveChanges({
  required BuildContext context,
  required UserModel oldUser,
  required String name,
  required String emailAddress,
  required String phoneNumber,
  required String address,
  required String dateOfBirth,
}) async {
  try {
    final uid = oldUser.uid;
    final updatedUser = UserModel(
      uid: uid,
      name: oldUser.name,
      email: oldUser.email,
      emailAddress: emailAddress,
      phoneNumber: phoneNumber,
      address: address,
      dateOfBirth: dateOfBirth,
      memberSince: oldUser.memberSince,
      totalWashes: oldUser.totalWashes,
      washesThisMonth: oldUser.washesThisMonth,
      rating: oldUser.rating,
      loyaltyPoints: oldUser.loyaltyPoints,
      photoUrl: oldUser.photoUrl,
      locations: [],
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updatedUser.toMap());

    // Update local cache + provider
    await context.read<UserProvider>().setUser(updatedUser);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error updating user info: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    // Start upload
    final uploadTask = storageRef.putFile(file);

    // Show upload progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(uploadTask: uploadTask),
    );

    // Wait for completion
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'photoUrl': downloadUrl,
    });

    // Update Provider
    final updatedUser = user.copyWith(photoUrl: downloadUrl);
    Provider.of<UserProvider>(context, listen: false).setUser(updatedUser);

    // Dismiss dialog
    if (context.mounted) Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated successfully')),
    );
  } catch (e) {
    debugPrint('Upload failed: $e');

    if (context.mounted) Navigator.of(context).pop(); // Ensure dialog is closed

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
              progress = snap.bytesTransferred / snap.totalBytes;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Uploading photo...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 10),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            );
          },
        ),
      ),
    );
  }
}
