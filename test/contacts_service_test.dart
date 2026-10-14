import 'package:flutter_test/flutter_test.dart';
import 'package:biic_chat_sbr/services/contacts_service.dart';

void main() {
  group('splitIntoBatches', () {
    test('returns no batches for an empty list', () {
      expect(splitIntoBatches<int>([]), isEmpty);
    });

    test('splits large address books into bounded batches without losing order', () {
      final input = List<int>.generate(1001, (index) => index);
      final batches = splitIntoBatches(input);

      expect(batches.map((batch) => batch.length), [500, 500, 1]);
      expect(batches.expand((batch) => batch).toList(), input);
      expect(batches.every((batch) => batch.length <= 500), isTrue);
    });

    test('supports a custom batch size', () {
      expect(splitIntoBatches([1, 2, 3, 4, 5], batchSize: 2), [
        [1, 2],
        [3, 4],
        [5],
      ]);
    });

    test('rejects a non-positive batch size', () {
      expect(
        () => splitIntoBatches([1], batchSize: 0),
        throwsArgumentError,
      );
    });
  });
}
