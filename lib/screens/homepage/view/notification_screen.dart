import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/logo_small.png', // Replace with your logo asset
                  height: 32,
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionTitle('Today'),
          _notificationCard(
            icon: Icons.credit_card,
            title: 'Trip assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          _notificationCard(
            icon: Icons.directions_car,
            title: 'Shared ride assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          const SizedBox(height: 18),
          _sectionTitle('Yesterday'),
          _notificationCard(
            icon: Icons.credit_card,
            title: 'Trip assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          _notificationCard(
            icon: Icons.directions_car,
            title: 'Shared ride assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          _notificationCard(
            icon: Icons.credit_card,
            title: 'Trip assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          _notificationCard(
            icon: Icons.directions_car,
            title: 'Shared ride assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
          const SizedBox(height: 18),
          _sectionTitle('May. 27 2023'),
          _notificationCard(
            icon: Icons.credit_card,
            title: 'Trip assigned',
            subtitle: 'Lorem ipsum dolor sit amet consectetur. Ultrici es tincidunt eleifend vitae',
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6C7A9C)),
      ),
    );
  }

  Widget _notificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: const Color(0xFFFFC107), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6C7A9C)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 