import 'package:flutter_test/flutter_test.dart';
import 'package:biic_chat_sbr/config/app_config.dart';
import 'package:biic_chat_sbr/main.dart';
import 'package:biic_chat_sbr/services/backend_service.dart';

void main() {
  testWidgets('BIIC CHAT app reaches a valid initial screen', (WidgetTester tester) async {
    await initializeBackend();
    await tester.pumpWidget(const BIICChatApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();

    if (AppConfig.hasSupabaseConfig) {
      expect(find.text('BIIC CHAT'), findsOneWidget);
    } else {
      expect(
        find.text('BIIC CHAT est temporairement indisponible'),
        findsOneWidget,
      );
    }
  });
}
