import 'package:flutter_test/flutter_test.dart';
import 'package:biic_chat_sbr/main.dart';

void main() {
  testWidgets('BIIC CHAT splash loads', (WidgetTester tester) async {
    await tester.pumpWidget(const BIICChatApp());

    expect(find.text('BIENVENUE SUR BIIC CHAT'), findsOneWidget);
  });
}
