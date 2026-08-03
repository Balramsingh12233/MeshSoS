import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/screens/chat_screen.dart';

/// MeshSOSApp is the root MaterialApp widget.
/// 
/// Setup Rationale:
/// Configures MaterialApp with the high-contrast dark emergency AppTheme 
/// and displays the Google Product Design ChatScreen as the primary home screen.
class MeshSOSApp extends StatelessWidget {
  const MeshSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatScreen(),
    );
  }
}