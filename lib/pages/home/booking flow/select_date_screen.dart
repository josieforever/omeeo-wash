import 'package:flutter/material.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/home/booking%20flow/common_widgets.dart';

class SelectDateScreen extends StatefulWidget {
  const SelectDateScreen({super.key});

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  late String routePath;
  DateTime pickedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              LnProgressIndicator(value: progressIndicatorValues[2]),
              const SizedBox(height: 24),
              Text(
                "When do you want your car cleaned?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Calendar widget
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.amber,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                    onDateChanged: (date) {
                      setState(() {
                        pickedDate = date;
                      });
                      debugPrint('Picked date: ${pickedDate}');
                    },
                  ),
                ),
              ),

              const Spacer(),

              // Continue button
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   child: SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       onPressed: () {
              //         // Handle continue
              //       },
              //       style: ElevatedButton.styleFrom(
              //         padding: const EdgeInsets.symmetric(vertical: 16),
              //         backgroundColor: Colors.grey[300], // inactive style
              //         foregroundColor: Colors.grey[600],
              //       ),
              //       child: const Text("Continue"),
              //     ),
              //   ),
              // ),
              // OmeeoButton(
              //   backgroundColor: lightPurple,
              //   text: "Continue",
              //   onPressed: () {
              //     context.push(routePath);
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
