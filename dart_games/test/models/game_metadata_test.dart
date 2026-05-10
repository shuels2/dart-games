import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/constants/game_filter_registry.dart';
import 'package:dart_games/models/game_metadata.dart';

void main() {
  group('GameMetadata.matchesFilters', () {
    final pgMeta = GameFilterRegistry.byId('pirates_grid')!;
    final ttMeta = GameFilterRegistry.byId('target_tag')!;
    final cdMeta = GameFilterRegistry.byId('carnival_derby')!;

    test('empty filters match all games', () {
      expect(pgMeta.matchesFilters(const {}), isTrue);
      expect(ttMeta.matchesFilters(const {}), isTrue);
      expect(cdMeta.matchesFilters(const {}), isTrue);
    });

    test('single criterion matches when value is selected', () {
      final filters = {
        FilterCriterion.maxPlayers: <Object>{MaxPlayersBucket.twoOnly},
      };
      expect(pgMeta.matchesFilters(filters), isTrue);
      expect(ttMeta.matchesFilters(filters), isFalse);
      expect(cdMeta.matchesFilters(filters), isFalse);
    });

    test('OR semantics within a criterion', () {
      // PG has twoOnly, TT has upToTen — selecting both should match both.
      final filters = {
        FilterCriterion.maxPlayers: <Object>{
          MaxPlayersBucket.twoOnly,
          MaxPlayersBucket.upToTen,
        },
      };
      expect(pgMeta.matchesFilters(filters), isTrue);
      expect(ttMeta.matchesFilters(filters), isTrue);
      // CD is upToEight — neither selected value matches.
      expect(cdMeta.matchesFilters(filters), isFalse);
    });

    test('AND semantics across criteria', () {
      // PG = twoOnly + strategy. Filter for both should match PG only.
      final filters = {
        FilterCriterion.maxPlayers: <Object>{MaxPlayersBucket.twoOnly},
        FilterCriterion.gameplayStyle: <Object>{GameplayStyle.strategy},
      };
      expect(pgMeta.matchesFilters(filters), isTrue);
      // CD = upToEight + race — fails the maxPlayers filter.
      expect(cdMeta.matchesFilters(filters), isFalse);
      // TT = upToTen + versus — fails both.
      expect(ttMeta.matchesFilters(filters), isFalse);
    });

    test('empty value-set in one criterion does not exclude games', () {
      // An entry with empty selected values is treated as "no filter".
      final filters = {
        FilterCriterion.maxPlayers: <Object>{MaxPlayersBucket.twoOnly},
        FilterCriterion.gameplayStyle: <Object>{}, // empty = no filter
      };
      expect(pgMeta.matchesFilters(filters), isTrue);
      expect(ttMeta.matchesFilters(filters), isFalse); // wrong maxPlayers
    });

    test('soloTeam filter matches Target Tag for Solo or Team', () {
      final filters = {
        FilterCriterion.soloTeam: <Object>{SoloTeamSupport.soloOrTeam},
      };
      expect(ttMeta.matchesFilters(filters), isTrue);
      expect(pgMeta.matchesFilters(filters), isFalse);
      expect(cdMeta.matchesFilters(filters), isFalse);
    });

    test('player interaction filter — Heavy matches battle games only', () {
      final filters = {
        FilterCriterion.playerInteraction: <Object>{PlayerInteraction.heavy},
      };
      // TT and MM are heavy.
      expect(ttMeta.matchesFilters(filters), isTrue);
      expect(GameFilterRegistry.byId('monster_mash')!.matchesFilters(filters),
          isTrue);
      // CD/PG are not.
      expect(cdMeta.matchesFilters(filters), isFalse);
      expect(pgMeta.matchesFilters(filters), isFalse);
    });
  });

  group('GameFilterRegistry', () {
    test('all 8 currently-shipped games are registered', () {
      const expectedIds = {
        'carnival_derby',
        'clockwork_quest',
        'gladiator_arena',
        'lunar_lander',
        'monster_mash',
        'pirates_grid',
        'reef_royale',
        'target_tag',
      };
      final actualIds = GameFilterRegistry.all.map((m) => m.gameId).toSet();
      expect(actualIds, equals(expectedIds));
    });

    test('every registered game has all required metadata fields populated',
        () {
      for (final m in GameFilterRegistry.all) {
        expect(m.gameId, isNotEmpty, reason: 'gameId must be non-empty');
        expect(m.displayName, isNotEmpty,
            reason: '${m.gameId} displayName must be non-empty');
        expect(m.gameplayStyles, isNotEmpty,
            reason: '${m.gameId} gameplayStyles must be non-empty');
      }
    });

    test('gameId values are unique', () {
      final ids = GameFilterRegistry.all.map((m) => m.gameId).toList();
      expect(ids.length, equals(ids.toSet().length));
    });

    test('byId returns null for unknown ids', () {
      expect(GameFilterRegistry.byId('not_a_real_game'), isNull);
    });

    test('byId returns the right entry for every registered id', () {
      for (final m in GameFilterRegistry.all) {
        expect(GameFilterRegistry.byId(m.gameId), same(m));
      }
    });

    test('every enum value in the filter criteria has at least one game', () {
      // Coverage check: every dropdown option should have at least one game
      // it filters to. If a value has zero games, the filter UI shows an
      // unselectable option that always returns the empty set — confusing.
      for (final v in MaxPlayersBucket.values) {
        final games = GameFilterRegistry.all.where((m) => m.maxPlayers == v);
        expect(games, isNotEmpty,
            reason: 'No game has maxPlayers=$v — orphaned filter option');
      }
      for (final v in GameplayStyle.values) {
        final games =
            GameFilterRegistry.all.where((m) => m.gameplayStyles.contains(v));
        expect(games, isNotEmpty,
            reason: 'No game has gameplayStyle=$v — orphaned filter option');
      }
      for (final v in PlayerInteraction.values) {
        final games =
            GameFilterRegistry.all.where((m) => m.playerInteraction == v);
        expect(games, isNotEmpty,
            reason: 'No game has playerInteraction=$v — orphaned filter option');
      }
      for (final v in GameLength.values) {
        final games = GameFilterRegistry.all.where((m) => m.gameLength == v);
        expect(games, isNotEmpty,
            reason: 'No game has gameLength=$v — orphaned filter option');
      }
      for (final v in SoloTeamSupport.values) {
        final games = GameFilterRegistry.all.where((m) => m.soloTeam == v);
        expect(games, isNotEmpty,
            reason: 'No game has soloTeam=$v — orphaned filter option');
      }
    });
  });

  group('GameFilterRegistry.filter', () {
    test('empty filters returns all registered games', () {
      final result = GameFilterRegistry.filter(const {});
      expect(result.length, equals(GameFilterRegistry.all.length));
    });

    test('Versus + Heavy returns Target Tag, Monster Mash, and Gladiator Arena', () {
      final result = GameFilterRegistry.filter({
        FilterCriterion.gameplayStyle: <Object>{GameplayStyle.versus},
        FilterCriterion.playerInteraction: <Object>{PlayerInteraction.heavy},
      });
      final ids = result.map((m) => m.gameId).toSet();
      expect(ids, equals({'target_tag', 'monster_mash', 'gladiator_arena'}));
    });

    test('Race style returns four race games (including Gladiator Arena)', () {
      final result = GameFilterRegistry.filter({
        FilterCriterion.gameplayStyle: <Object>{GameplayStyle.race},
      });
      final ids = result.map((m) => m.gameId).toSet();
      expect(ids, equals({'carnival_derby', 'clockwork_quest', 'lunar_lander', 'gladiator_arena'}));
    });

    test('Solo or Team returns only Target Tag', () {
      final result = GameFilterRegistry.filter({
        FilterCriterion.soloTeam: <Object>{SoloTeamSupport.soloOrTeam},
      });
      expect(result.map((m) => m.gameId).toList(), equals(['target_tag']));
    });

    test('two-only + strategy returns only Pirate\'s Grid', () {
      final result = GameFilterRegistry.filter({
        FilterCriterion.maxPlayers: <Object>{MaxPlayersBucket.twoOnly},
        FilterCriterion.gameplayStyle: <Object>{GameplayStyle.strategy},
      });
      expect(result.map((m) => m.gameId).toList(), equals(['pirates_grid']));
    });

    test('contradictory filters return empty (solo+team AND strategy)', () {
      // No game has solo-or-team support AND strategy style simultaneously.
      final result = GameFilterRegistry.filter({
        FilterCriterion.gameplayStyle: <Object>{GameplayStyle.strategy},
        FilterCriterion.soloTeam: <Object>{SoloTeamSupport.soloOrTeam},
      });
      expect(result, isEmpty);
    });
  });
}
