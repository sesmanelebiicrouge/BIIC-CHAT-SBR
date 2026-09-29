import 'package:flutter_test/flutter_test.dart';
import 'package:biic_chat_sbr/main.dart';

void main() {
  testWidgets('BIIC CHAT app loads with title', (WidgetTester tester) async {
    await tester.pumpWidget(const BIICChatApp());

    expect(find.text('BIIC CHAT'), findsOneWidget);
  });
}
