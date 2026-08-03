import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_sos/app.dart';

void main() {
  testWidgets('MeshSOSApp ChatScreen Google Product Design UI test', (WidgetTester tester) async {
    // Build MeshSOSApp wrapped in ProviderScope for Riverpod state management
    await tester.pumpWidget(
      const ProviderScope(
        child: MeshSOSApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title & Google Product Design chat UI elements
    expect(find.text('MeshSOS'), findsOneWidget);
    expect(find.text('Type a message...'), findsOneWidget);
    expect(find.text('Mesh Active - 3 Peers Nearby'), findsOneWidget);
  });
}
