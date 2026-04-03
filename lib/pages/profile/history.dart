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
      'pickupLocation': 'Teikofio Streetargaggegege5gw5gw35gw35g35g35',
      'laundryService': 'FreshFold Laundry',
      'price': '31 GHS',
      'status': 'completed',
    },
    {
      'date': 'Monday, November 24, 2025',
      'service': 'Wash & Iron',
      'time': '17:20',
      'pickupLocation': 'Teikofio Street',
      'laundryService': 'SparkleSpin Wash',
      'price': '47 GHS',
      'status': 'completed',
    },
    {
      'date': 'Saturday, October 25, 2025',
      'service': 'Wash & Fold',
      'time': '13:18',
      'pickupLocation': 'Teikofio Street',
      'laundryService': 'PurePress Laundry',
      'price': '33 GHS',
      'status': 'completed',
    },
    {
      'date': 'Wednesday, September 24, 2025',
      'service': 'Wash & Iron',
      'time': '07:50',
      'pickupLocation': 'Teikofio Street',
      'laundryService': 'CloudClean Laundry',
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
                    const SizedBox(width: 10),
                    _buildFilterChip('Wash & Fold'),
                    const SizedBox(width: 10),
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
                          pickupLocation: item['pickupLocation'],
                          laundryService: item['laundryService'],
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 44, 44, 44)
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
              title == 'Wash & Fold'
                  ? Transform.scale(
                      scale: 0.9,
                      child: Image.asset(
                        isSelected
                            ? 'assets/images/machine.png'
                            : 'assets/images/black_machine.png',
                        height: 30,
                        width: 30,
                      ),
                    )
                  : Transform.scale(
                      scale: 1.15,
                      child: Image.asset(
                        isSelected
                            ? 'assets/images/machine_iron.png'
                            : 'assets/images/black_machine_iron.png',
                        height: 30,
                        width: 30,
                      ),
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
  final String pickupLocation;
  final String laundryService;
  final String price;
  final bool cancelled;
  final bool showActions;

  const _OrderCard({
    required this.service,
    required this.time,
    required this.pickupLocation,
    required this.laundryService,
    required this.price,
    this.cancelled = false,
    this.showActions = false,
  });

  String truncateText(String value, {int maxLength = 16}) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 224, 224, 224),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                service == 'Wash & Fold'
                    ? Icons.local_laundry_service_rounded
                    : Icons.iron_rounded,
                color: const Color.fromARGB(255, 161, 0, 134),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$service,  $time',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${truncateText(pickupLocation)} → ${truncateText(laundryService)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: cancelled ? Colors.red : Colors.grey.shade600,
                        fontWeight: cancelled
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
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
