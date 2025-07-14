import 'package:flutter/material.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: const Center(
        child: Text('Refer friends and earn rewards!'),
      ),
    );
  }
} 