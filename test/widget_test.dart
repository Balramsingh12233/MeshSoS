import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_sos/app.dart';

void main() {
  testWidgets('MeshSOSApp baseline widget smoke test', (WidgetTester tester) async {
    // Build MeshSOSApp foundation screen
    await tester.pumpWidget(const MeshSOSApp());

    // Verify title and emergency UI elements exist
    expect(find.text('MeshSOS Emergency System'), findsOneWidget);
    expect(find.text('BROADCAST SOS'), findsOneWidget);
    expect(find.text('Network Mode: Offline Mesh Active'), findsOneWidget);
  });
}
