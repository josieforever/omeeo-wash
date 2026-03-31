import 'package:flutter/material.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> orders = [
    {
      'date': 'Tuesday, March 17',
      'service': 'Wash & Fold',
      'time': '13:30',
      'route': 'Teikofio Street → Gulf Road, 8',
      'price': '31 GHS',
      'status': 'completed',
    },
    {
      'date': 'Monday, November 24, 2025',
      'service': 'Wash & Iron',
      'time': '17:20',
      'route': 'Teikofio Street → Spintex Road, 86',
      'price': '47 GHS',
      'status': 'completed',
    },
    {
      'date': 'Saturday, October 25, 2025',
      'service': 'Wash & Fold',
      'time': '13:18',
      'route': 'Teikofio Street → Asafoatse Brown Road, 9',
      'price': '33 GHS',
      'status': 'completed',
    },
    {
      'date': 'Wednesday, September 24, 2025',
      'service': 'Wash & Iron',
      'time': '07:50',
      'route': 'Canceled',
      'price': '0 GHS',
      'status': 'cancelled',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredOrders = selectedFilter == 'All'
        ? orders
        : orders.where((e) => e['service'] == selectedFilter).toList();

    String? currentDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              /// Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'My washes and orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              /// Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 12),
                    _buildFilterChip('Wash & Fold'),
                    const SizedBox(width: 12),
                    _buildFilterChip('Wash & Iron'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Orders List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final item = filteredOrders[index];

                    final showDate = currentDate != item['date'];
                    currentDate = item['date'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              item['date'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],

                        _OrderCard(
                          service: item['service'],
                          time: item['time'],
                          route: item['route'],
                          price: item['price'],
                          cancelled: item['status'] == 'cancelled',
                          showActions: index == 0,
                        ),

                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String title) {
    final isSelected = selectedFilter == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 62, 0, 161)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (title != 'All') ...[
              Icon(
                title == 'Wash & Fold'
                    ? Icons.local_laundry_service_rounded
                    : Icons.iron_rounded,
                size: 20,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String service;
  final String time;
  final String route;
  final String price;
  final bool cancelled;
  final bool showActions;

  const _OrderCard({
    required this.service,
    required this.time,
    required this.route,
    required this.price,
    this.cancelled = false,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    62,
                    0,
                    161,
                  ).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  service == 'Wash & Fold'
                      ? Icons.local_laundry_service_rounded
                      : Icons.iron_rounded,
                  color: const Color.fromARGB(255, 62, 0, 161),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$service, $time',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route,
                      style: TextStyle(
                        fontSize: 17,
                        color: cancelled ? Colors.red : Colors.grey.shade600,
                        fontWeight: cancelled
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          if (showActions && !cancelled) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.headset_mic_outlined,
                    title: 'Help',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.refresh_rounded,
                    title: 'Book again',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
