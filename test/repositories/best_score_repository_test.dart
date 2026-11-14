import 'package:flutter_test/flutter_test.dart';
import 'package:hinge_angle_game/repositories/best_score_repository.dart';
import 'package:hinge_angle_game/services/best_score_store.dart';
import 'package:hinge_angle_game/utils/result.dart';

import '../helpers/fakes.dart';

/// どの操作でも例外を投げる保存先（端末保存の失敗を再現する）。
class _BrokenStore() implements BestScoreStore {
  @override
  Future<int?> load({required String providerId, required int rounds}) =>
      throw Exception('load failed');

  @override
  Future<bool> submit({
    required String providerId,
    required int rounds,
    required int score,
  }) => throw Exception('submit failed');
}

void main() {
  group('BestScoreRepository', () {
    setUp(useInMemoryPrefs);

    test('記録がなければ Ok(null)', () async {
      final result = await inMemoryBestScores().load(
        providerId: 'hinge',
        rounds: 5,
      );
      expect(result, isA<Ok<int?>>());
      expect((result as Ok<int?>).value, isNull);
    });

    test('初回は前の記録なしで自己ベスト、次に上回れば前の記録つきで自己ベスト', () async {
      final repo = inMemoryBestScores();
      final first = await repo.submit(
        providerId: 'hinge',
        rounds: 5,
        score: 300,
      );
      expect((first as Ok<BestScoreUpdate>).value, (
        previousBest: null,
        best: 300,
        isNewBest: true,
      ));
      final lower = await repo.submit(
        providerId: 'hinge',
        rounds: 5,
        score: 200,
      );
      expect((lower as Ok<BestScoreUpdate>).value, (
        previousBest: 300,
        best: 300,
        isNewBest: false,
      ));
      final higher = await repo.submit(
        providerId: 'hinge',
        rounds: 5,
        score: 400,
      );
      expect((higher as Ok<BestScoreUpdate>).value, (
        previousBest: 300,
        best: 400,
        isNewBest: true,
      ));
      final loaded = await repo.load(providerId: 'hinge', rounds: 5);
      expect((loaded as Ok<int?>).value, 400);
    });

    test('保存先が失敗したら例外を投げずに Error を返す', () async {
      final repo = BestScoreRepository(_BrokenStore());
      final loaded = await repo.load(providerId: 'hinge', rounds: 5);
      expect(loaded, isA<Error<int?>>());
      expect((loaded as Error<int?>).error.toString(), contains('load failed'));
      final submitted = await repo.submit(
        providerId: 'hinge',
        rounds: 5,
        score: 100,
      );
      expect(submitted, isA<Error<BestScoreUpdate>>());
    });
  });
}
