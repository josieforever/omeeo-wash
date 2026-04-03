// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:omeeowash/widgets.dart/responsiveness.dart';
// import 'package:omeeowash/widgets.dart/utility_widgets.dart';

// import 'chat.dart';

// class HelpList extends StatelessWidget {
//   const HelpList({super.key});

//   Future<List<Map<String, dynamic>>> fetchClients() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('admin')
//         .doc('idforadminv1')
//         .collection('help_chats')
//         .get();

//     // Extract fields from documents
//     return snapshot.docs.map((doc) {
//       final data = doc.data();
//       return {
//         'userId': data['userId'],
//         'username': data['username'],
//         'last_message': data['last_message'],
//       };
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 244, 248, 255),
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.centerRight,
//                 end: Alignment.centerLeft,
//                 colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
//               ),
//             ),
//           ),
//           Positioned.fill(
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.9,
//               color: const Color.fromARGB(213, 255, 255, 255),
//             ),
//           ),
//           Positioned.fill(
//             child: Lottie.asset(
//               'assets/animations/background_animation_light.json',
//               fit: BoxFit.cover,
//             ),
//           ),
//           Positioned.fill(
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.9,
//               color: const Color.fromARGB(100, 255, 255, 255),
//             ),
//           ),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: MediaQuery.of(context).size.width,
//                 padding: const EdgeInsets.all(10),
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.centerRight,
//                     end: Alignment.centerLeft,
//                     colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           mainAxisSize: MainAxisSize.max,
//                           children: [
//                             CustomText(
//                               text: 'Clients',
//                               textColor: Theme.of(
//                                 context,
//                               ).textTheme.headlineLarge?.color,
//                               textSize: TextSizes.heading2,
//                               textWeight: FontWeight.w900,
//                             ),
//                           ],
//                         ),
//                         GoBack(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               FutureBuilder<List<Map<String, dynamic>>>(
//                 future: fetchClients(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }

//                   final clients = snapshot.data ?? [];

//                   if (clients.isEmpty) {
//                     return const Center(child: Text('No clients found.'));
//                   }

//                   return Expanded(
//                     child: ListView.builder(
//                       itemCount: clients.length,
//                       itemBuilder: (context, index) {
//                         final client = clients[index];
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (BuildContext context) => Chat.admin(
//                                   clientId: client['userId'],
//                                   clientName: client['username'] ?? 'User',
//                                   isAdmin: true,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Column(
//                             children: [
//                               ListTile(
//                                 leading: CircleAvatar(
//                                   radius: 25,

//                                   // backgroundImage: client['photoUrl'] != null
//                                   //     ? NetworkImage(client['photoUrl'])
//                                   //     : null,
//                                   child: const Icon(Icons.person),
//                                   // child: client['photoUrl'] == null
//                                   //     ? const Icon(Icons.person)
//                                   //     : null,
//                                 ),
//                                 title: Text(
//                                   client['username'] ?? 'No Name',
//                                   style: TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                                 subtitle: Text(
//                                   client['last_message'] ?? "none",
//                                 ),
//                                 trailing: Icon(Icons.more_vert),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/pages/profile/help/live_chat/methods.dart';

import 'chat.dart';

class HelpList extends StatelessWidget {
  const HelpList({super.key});

  Future<List<Map<String, dynamic>>> fetchClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('idforadminv1')
        .collection('help_chats')
        .get();

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 22,
          ),
        ),
        title: const Text(
          'Clients',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    'Something went wrong.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }

          final clients = snapshot.data ?? [];

          if (clients.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 42,
                        color: Color(0xFF8B8FA3),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No clients found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Client conversations will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: Color(0xFF5B6EF5),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Support Conversations',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${clients.length} client${clients.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: clients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    final name = (client['username'] ?? 'No Name')
                        .toString()
                        .trim();
                    final lastMessage =
                        (client['last_message'] ?? 'No messages yet')
                            .toString()
                            .trim();

                    return GestureDetector(
                      onTap: () {
                        customRoute(
                          context,
                          Chat.admin(
                            clientId: client['userId'],
                            clientName: name.isEmpty ? 'User' : name,
                            isAdmin: true,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFF0F1F5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6D66F6),
                                    Color(0xFFA558F2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? 'User' : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lastMessage.isEmpty
                                        ? 'No messages yet'
                                        : lastMessage,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.35,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F6FB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF6D66F6),
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
