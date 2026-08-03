import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_sos/app.dart';

void main() {
  testWidgets('MeshSOSApp DashboardScreen Google Product Design UI test', (WidgetTester tester) async {
    // Build MeshSOSApp wrapped in ProviderScope for Riverpod state management
    await tester.pumpWidget(
      const ProviderScope(
        child: MeshSOSApp(),
      ),
    );
    // Use pump() for single frame rendering with infinite radar animation
    await tester.pump();

    // Verify Dashboard UI elements: Logo, 'Mesh Online' badge, SOS panic card, Recent Conversations
    expect(find.text('Mesh Online'), findsOneWidget);
    expect(find.text('Emergency SOS Panic'), findsOneWidget);
    expect(find.text('ONE-TAP EMERGENCY SOS'), findsOneWidget);
    expect(find.text('Recent Conversations'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);
  });
}
