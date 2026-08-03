import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  // ProviderScope must wrap the whole app - every Riverpod provider
  // anywhere in the app depends on this being here. Nothing else
  // belongs in main.dart at this stage.
  runApp(const ProviderScope(child: MeshSOSApp()));
}