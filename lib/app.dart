import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class MeshSOSApp extends StatelessWidget {
  const MeshSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Placeholder - replaced with ChatScreen() in Week 2-3 once
      // features/mesh_chat/presentation/screens/chat_screen.dart exists.
      // Don't build navigation/routes yet - there's only one screen so far.
      home: const Scaffold(
        body: Center(child: Text('MeshSOS - setup working')),
      ),
    );
  }
}