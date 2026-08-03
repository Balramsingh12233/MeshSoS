import 'package:flutter/material.dart';

/// AppColors defines the visual color system for MeshSOS.
/// 
/// System Design Rationale for Big Tech / Emergency Apps:
/// 1. High-Contrast Dark Mode: Saves battery on OLED screens during extended power outages 
///    and ensures high legibility under harsh sunlight or dark emergency conditions.
/// 2. Dedicated Transport Colors:
///    - Mesh Green: Signals active peer-to-peer radio connection (BLE/WiFi Direct).
///    - Cloud Blue: Signals active internet connectivity to Cloudflare backend.
///    - SMS Amber: Signals carrier network cellular fallback mode.
/// 3. Reserved SOS Red: A distinct warm red reserved EXCLUSIVELY for emergency panic actions 
///    so it immediately grabs the user's attention without visual confusion.
abstract class AppColors {
  // Pure dark background to conserve battery on OLED displays during disasters
  static const Color background = Color(0xFF121212);
  
  // Elevated card/container surface color for visual hierarchy
  static const Color surface = Color(0xFF1E1E1E);
  
  // Slightly lighter surface for input fields and active state highlights
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // Core Emergency SOS Accent Color - NEVER used for non-emergency UI elements
  static const Color sosAccent = Color(0xFFFF4D4D);
  
  // High contrast white text for maximum readability
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  // Muted secondary text for metadata (timestamps, hop counts, device IDs)
  static const Color textSecondary = Color(0xFFA0A0A0);

  // Transport Layer Color System
  // Green = Direct Bluetooth / WiFi Direct Mesh network relay
  static const Color transportMesh = Color(0xFF00E676);
  
  // Blue = Cloudflare Workers + D1 database online sync
  static const Color transportCloud = Color(0xFF29B6F6);
  
  // Amber/Orange = Native device SIM SMS fallback mode
  static const Color transportSms = Color(0xFFFFB74D);

  // Border & Divider color for clean layout demarcation
  static const Color border = Color(0xFF333333);
}
