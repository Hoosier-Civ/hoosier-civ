import 'package:flutter/material.dart';

class MissionDetailScreen extends StatelessWidget {
  final String id;

  const MissionDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('MissionDetailScreen'),
      ),
    );
  }
}
