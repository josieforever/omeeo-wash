import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class Addresses extends StatelessWidget {
  const Addresses({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    userProvider.loadUser(uid: FirebaseAuth.instance.currentUser!.uid);
    final user = userProvider.user;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(213, 255, 255, 255),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(100, 255, 255, 255),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AddressesTopBar(),
                  user!.locations.isEmpty
                      ? NoAddressBookScreen()
                      : AddressesMiddleBar(),
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

class AddressesTopBar extends StatelessWidget {
  const AddressesTopBar({super.key});
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
                    text: 'Addresses',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Manage your saved locations',
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

class AddressesMiddleBar extends StatelessWidget {
  const AddressesMiddleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final locations = userProvider.user?.locations ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegularIconButton(
            onPressed: () => showAddLocationDialog(context),
            borderRadius: 7,
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF9335EA), Color(0xFFB461F5), Color(0xFF9335EA)],
            ),
            icon: Icon(
              FontAwesomeIcons.plus,
              color: Theme.of(context).textTheme.headlineLarge?.color,
              size: IconSizes.small,
            ),
            textWidget: CustomText(
              text: 'Add New Address',
              textColor: Theme.of(context).textTheme.headlineLarge?.color,
              textSize: TextSizes.subtitle2,
              textWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),

          // Dynamic Address List
          if (locations.isEmpty)
            Center(
              child: CustomText(
                text: "No saved addresses yet.",
                textSize: TextSizes.bodyText2,
                textColor: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final location = locations[index];
                final type = location['addressType'] ?? 'Other';
                final label = location['label'] ?? 'Unnamed';
                final address = location['address'] ?? 'No address';
                final isDefault = location['isDefault'] ?? false;

                Icon icon;
                switch (type.toLowerCase()) {
                  case 'home':
                    icon = Icon(
                      Icons.cottage,
                      color: Color(0xFF9335EA),
                      size: IconSizes.tiny,
                    );
                    break;
                  case 'work':
                    icon = Icon(
                      Icons.apartment,
                      color: Color(0xFF9335EA),
                      size: IconSizes.tiny,
                    );
                    break;
                  default:
                    icon = Icon(
                      FontAwesomeIcons.locationDot,
                      color: Color(0xFF9335EA),
                      size: IconSizes.tiny,
                    );
                }

                return Dismissible(
                  key: Key('$label-$index'),
                  direction: DismissDirection.startToEnd,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Address'),
                        content: const Text(
                          'Are you sure you want to delete this address?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) async {
                    final updatedLocations = List<Map<String, String>>.from(
                      locations,
                    )..removeAt(index);
                    final updatedUser = userProvider.user!.copyWith(
                      locations: updatedLocations,
                    );

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(updatedUser.uid)
                          .set(updatedUser.toMap());

                      await userProvider.setUser(updatedUser);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Failed to delete address"),
                        ),
                      );
                    }
                  },
                  child: LocationButton(
                    textWidget1: type,
                    textWidget2: address,
                    textWidget3: label,
                    isDefault: isDefault,
                    scale: 1.8,
                    icon: icon,
                    onPressed: () {
                      // Optional: Define on tap behavior
                    },
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class LocationButton extends StatelessWidget {
  final bool? isDefault;
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;

  final double? scale;
  final VoidCallback onPressed;
  const LocationButton({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    required this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,

    this.stars,
    this.animation,
    this.scale,
    this.isDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Theme.of(context).textTheme.headlineLarge?.color,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(26, 12, 0, 235),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6), // x, y
          ),
        ],
      ),
      padding: EdgeInsets.all(7),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(32, 137, 43, 226),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Transform.scale(
                  scale: scale,
                  child: Center(child: icon),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.72,

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(
                          text: textWidget1,
                          textColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          textSize: TextSizes.bodyText2,
                          textWeight: FontWeight.w800,
                        ),
                        isDefault! ? const SizedBox(width: 10) : SizedBox(),
                        isDefault!
                            ? RegularIconButton(
                                onPressed: () {},
                                borderRadius: 50,
                                backgroundColor: Color.fromARGB(
                                  50,
                                  138,
                                  43,
                                  226,
                                ),
                                icon: Icon(
                                  FontAwesomeIcons.solidStar,
                                  color: Colors.amber,
                                  size: 10,
                                ),
                                textWidget: CustomText(
                                  text: 'Default',
                                  textColor: Color(0xFF9335EA),
                                  textSize: TextSizes.bodyText2,
                                  textWeight: FontWeight.bold,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(115, 204, 204, 255),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            FontAwesomeIcons.penToSquare,
                            size: IconSizes.small,
                            color: Color(0xFF9335EA),
                          ),
                        ),

                        const SizedBox(width: 15),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(115, 204, 204, 255),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            FontAwesomeIcons.trash,
                            size: IconSizes.small,
                            color: Color(0xFF9335EA),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CustomText(
                text: textWidget2!,
                textColor: Theme.of(context).textTheme.bodyMedium?.color,
                textSize: TextSizes.bodyText2,
              ),
              CustomText(
                text: textWidget3,
                textColor: Theme.of(context).textTheme.bodyMedium?.color,
                textSize: TextSizes.bodyText2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NoAddressBookScreen extends StatelessWidget {
  const NoAddressBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 250, 225, 255),
                  Color.fromARGB(255, 221, 217, 245),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFF9A5DF1),
                  child: Icon(Icons.location_on, color: Colors.white, size: 35),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Address Book is Empty',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Save your favorite locations to make ordering faster and easier. Add your home, office, or any other place you frequently order to.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                RegularIconButton(
                  onPressed: () {
                    showAddLocationDialog(context);
                  },
                  borderRadius: 10,
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: const [
                      Color(0xFF6D66F6), // Main purple tone
                      Color(0xFF9335EA),
                      // Lighter lavender
                    ],
                  ),
                  icon: Icon(
                    FontAwesomeIcons.plus,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                    size: IconSizes.small,
                  ),
                  textWidget: CustomText(
                    text: 'Add Your First Address',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.subtitle2,
                    textWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    addressTypeBox(
                      icon: Icons.home,
                      label: 'Home',
                      color: Color(0xFF9335EA),
                    ),
                    addressTypeBox(
                      icon: Icons.apartment,
                      label: 'Work',
                      color: const Color.fromARGB(255, 0, 140, 255),
                    ),
                    addressTypeBox(
                      icon: Icons.location_pin,
                      label: 'Other',
                      color: const Color.fromARGB(255, 255, 0, 89),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  'Quick Tips',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 10),
                tipRow(
                  Colors.green,
                  'Add detailed addresses for faster checkout',
                ),
                tipRow(
                  Colors.blue,
                  'Set one address as default for convenience',
                ),
                tipRow(
                  Colors.purple,
                  'Use custom labels to easily identify locations',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget addressTypeBox({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}

class tipRow extends StatelessWidget {
  final Color dotColor;
  final String text;

  const tipRow(this.dotColor, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: dotColor, size: 10),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

void showAddLocationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final formKey = GlobalKey<FormState>();
      final label = TextEditingController();
      final address = TextEditingController();
      String? selectedAddressType = 'Other'; // Initial value for the dropdown

      // List of items for the dropdown
      final List<String> addressTypes = ['Home', 'Work', 'Other'];

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      CustomText(
                        text: 'Add New Address',
                        textSize: TextSizes.bodyText1,
                        textColor: Theme.of(context).textTheme.bodyLarge?.color,
                        textWeight: FontWeight.w900,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Align children to the start (left)
                              mainAxisSize: MainAxisSize
                                  .min, // Take minimum space vertically
                              children: [
                                // Label for the dropdown
                                CustomText(
                                  text: 'Address Type',
                                  textSize: TextSizes.bodyText2,
                                  textColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  textWeight: FontWeight.bold,
                                ),

                                // Dropdown form field
                                DropdownButtonFormField<String>(
                                  value: selectedAddressType,
                                  hint: CustomText(
                                    text: 'other',
                                    textColor: const Color.fromARGB(
                                      255,
                                      91,
                                      91,
                                      91,
                                    ),
                                    textWeight: FontWeight.bold,
                                    textSize: TextSizes.caption,
                                  ),
                                  // Currently selected value
                                  decoration: InputDecoration(
                                    // Border styling to match the image (rounded corners, subtle border)
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        8.0,
                                      ), // Rounded corners
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(
                                        color: AppColors.black,
                                        width: 2.0,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ), // Padding inside the field
                                    fillColor: Colors
                                        .white, // Background color of the field
                                    filled: true,
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                  ), // Dropdown arrow icon
                                  iconEnabledColor:
                                      Colors.black54, // Color of the arrow icon
                                  elevation: 2, // Shadow for the dropdown menu
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.black,
                                  ),
                                  onChanged: (String? newValue) {
                                    // Update the selected value when the user picks a new one
                                    setState(() {
                                      selectedAddressType = newValue;
                                    });
                                  },
                                  items: addressTypes
                                      .map<DropdownMenuItem<String>>((
                                        String value,
                                      ) {
                                        // Create a dropdown item for each address type
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Email
                            CustomText(
                              text: 'Label',
                              textSize: TextSizes.bodyText2,
                              textColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              textWeight: FontWeight.bold,
                            ),

                            TextFormField(
                              cursorColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              controller: label,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter label';
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
                                hintText: "e.g., Mom's House, Gym, etc.",
                                hintStyle: TextStyle(
                                  fontSize: TextSizes.caption,
                                  color: const Color.fromARGB(255, 91, 91, 91),
                                  fontWeight: FontWeight.bold,
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  gapPadding: 10,
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        AppColors.textPrimary,
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
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
                            // Password
                            CustomText(
                              text: 'Address',
                              textSize: TextSizes.bodyText2,
                              textColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              textWeight: FontWeight.bold,
                            ),

                            TextFormField(
                              cursorColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              controller: address,

                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your address';
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
                                hintText: 'Enter full address',
                                hintStyle: TextStyle(
                                  fontSize: TextSizes.caption,
                                  color: const Color.fromARGB(255, 91, 91, 91),
                                  fontWeight: FontWeight.bold,
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  gapPadding: 10,
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color ??
                                        AppColors.textPrimary,
                                    width: 2.0,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RegularButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newLabel = label.text.trim();
                              final newAddress = address.text.trim();

                              final newLocation = {
                                'addressType': selectedAddressType ?? 'Other',
                                'label': newLabel,
                                'address': newAddress,
                                'isDefault': false,
                              };

                              final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false,
                              );
                              final currentUser = userProvider.user;

                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("User not loaded"),
                                  ),
                                );
                                return;
                              }

                              // Add the new location to the list
                              final updatedLocations =
                                  List<Map<String, dynamic>>.from(
                                    currentUser.locations,
                                  )..add(newLocation);

                              final updatedUser = currentUser.copyWith(
                                locations: updatedLocations,
                              );

                              try {
                                // Save user via provider
                                await userProvider.setUser(updatedUser);

                                // Update in Firestore (already done inside setUser)
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(updatedUser.uid)
                                    .set(updatedUser.toMap());

                                Navigator.pop(context);
                              } catch (e) {
                                debugPrint("Failed to update address: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Failed to save address"),
                                  ),
                                );
                              }
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
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textWidget: CustomText(
                            text: 'Add Address',
                            textColor: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                            textSize: TextSizes.caption,
                            textWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
