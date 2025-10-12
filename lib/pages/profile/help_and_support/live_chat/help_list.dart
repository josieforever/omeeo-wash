import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

import 'chat.dart';

class HelpList extends StatelessWidget {
  const HelpList({super.key});

  Future<List<Map<String, dynamic>>> fetchClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('idforadminv1')
        .collection('help_chats')
        .get();

    // Extract fields from documents
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': data['userId'],
        'username': data['username'],
        'last_message': data['last_message'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            CustomText(
                              text: 'Clients',
                              textColor: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.color,
                              textSize: TextSizes.heading2,
                              textWeight: FontWeight.w900,
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
                  ],
                ),
              ),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchClients(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final clients = snapshot.data ?? [];

                  if (clients.isEmpty) {
                    return const Center(child: Text('No clients found.'));
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) => Chat.admin(
                                  clientId: client['userId'],
                                  clientName: client['username'] ?? 'User',
                                  isAdmin: true,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 25,

                                  // backgroundImage: client['photoUrl'] != null
                                  //     ? NetworkImage(client['photoUrl'])
                                  //     : null,
                                  child: const Icon(Icons.person),
                                  // child: client['photoUrl'] == null
                                  //     ? const Icon(Icons.person)
                                  //     : null,
                                ),
                                title: Text(
                                  client['username'] ?? 'No Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  client['last_message'] ?? "none",
                                ),
                                trailing: Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
