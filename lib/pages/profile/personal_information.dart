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
import 'package:omeeowash/widgets.dart/responsiveness.dart';
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
    // Load the user ONCE after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<UserProvider>().loadUser(uid: uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when user object changes
    final user = context.select<UserProvider, UserModel?>((p) => p.user);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PersonalInformationTopBar(),
              if (user == null) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ] else ...[
                ProfilePhotoCard(
                  user: user,
                  onUploadTap: () => handleUploadPhoto(context, user),
                ),
                UpdateBasicInformation(user: user),
                const SizedBox(height: 30),
              ],
            ],
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
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),

          GoBack(
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'Personal Information',
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.heading2,
                textWeight: FontWeight.w900,
              ),
              CustomText(
                text: 'Update your details',
                textColor: Theme.of(context).colorScheme.surface,
                textSize: TextSizes.subtitle2,
              ),
            ],
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
    required this.onUploadTap,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = user.photoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
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
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl) : null,
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
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.camera,
                        size: 14,
                        color: Theme.of(context).colorScheme.inversePrimary,
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: TextSizes.subtitle1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Update your profile picture\nMax file size: 5MB',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: TextSizes.bodyText2,
                  fontWeight: FontWeight.normal,
                ),
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
                                        textColor: Theme.of(
                                          context,
                                        ).colorScheme.inversePrimary,
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
                                        textColor: Theme.of(
                                          context,
                                        ).colorScheme.inversePrimary,
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
                                    textColor: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                  ),
                                ),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: 7,
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    /* Theme.of(
                    context,
                  ).textTheme.headlineMedium?.color, */
                    vertical: 10,
                    horizontal: 40,
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
      uid: oldUser.uid,
      name: name, // <- use the new value
      email: oldUser.email, // keep auth email if that's your intention
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
      locations: oldUser.locations, // keep existing if available
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
