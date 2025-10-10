import 'package:flutter/material.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class Methods {
  Future<bool?> showDeleteConfirmationDialog(BuildContext context, onpress) {
    return showDialog<bool>(
      barrierColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 223, 223, 223),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CustomText(
                  text: "Messages deleted cannot be restored!",
                  textAlign: TextAlign.left,
                  textSize: 16,
                  textWeight: FontWeight.w600,
                  textColor: Colors.black,
                ),

                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(
                          255,
                          210,
                          179,
                          179,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: CustomText(
                        text: "Cancel",
                        textWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          104,
                          69,
                          247,
                        ),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onpress,
                      child: CustomText(
                        text: "Agree",
                        textWeight: FontWeight.bold,
                        textColor: Colors.white,
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
  }

  Future<void> showMediaPickerDialog(
    BuildContext context,
    VoidCallback pickImage,
    VoidCallback pickVideo,
  ) async {
    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 223, 223, 223),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: CustomText(text: "Choose Media", textWeight: FontWeight.bold),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Picture Button
              InkWell(
                onTap: () {
                  pickImage();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 8),
                    CustomText(text: "Picture"),
                  ],
                ),
              ),

              // Video Button
              InkWell(
                onTap: () {
                  pickVideo();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 8),
                    CustomText(text: "Video"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
