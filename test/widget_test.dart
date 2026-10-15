import 'package:flutter_test/flutter_test.dart';
import 'package:nexlearn/main.dart';

void main() {
  testWidgets('NexLearn app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NexLearnApp());

    expect(find.byType(NexLearnApp), findsOneWidget);
  });
}
