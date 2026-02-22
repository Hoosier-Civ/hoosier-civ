import 'package:flutter/material.dart';

class BillDetailScreen extends StatelessWidget {
  final String id;

  const BillDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('BillDetailScreen'),
      ),
    );
  }
}
