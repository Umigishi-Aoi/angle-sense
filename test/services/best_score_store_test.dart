import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/services/best_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  group('BestScoreStore', () {
    setUp(useInMemoryPrefs);

    test('上回ったときだけ保存し、入力源・問題数ごとに分ける', () async {
      final store = BestScoreStore(prefs: SharedPreferencesAsync());
      expect(await store.load(providerId: 'hinge', rounds: 10), isNull);
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 500),
        isTrue,
      );
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 500),
        isFalse,
      );
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 300),
        isFalse,
      );
      expect(await store.load(providerId: 'hinge', rounds: 10), 500);
      expect(await store.load(providerId: 'tilt', rounds: 10), isNull);
      expect(await store.load(providerId: 'hinge', rounds: 5), isNull);
      expect(
        await store.submit(providerId: 'hinge', rounds: 10, score: 700),
        isTrue,
      );
      expect(await store.load(providerId: 'hinge', rounds: 10), 700);
    });
  });
}
