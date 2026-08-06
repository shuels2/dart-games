import 'package:flutter_test/flutter_test.dart';
import 'package:dart_games/utils/dart_sector.dart';

void main() {
  group('DartSector.parse', () {
    test('parses singles, doubles and triples in either case', () {
      expect(DartSector.parse('S20').ring, DartRing.single);
      expect(DartSector.parse('S20').face, 20);
      expect(DartSector.parse('s15').ring, DartRing.single);
      expect(DartSector.parse('D20').ring, DartRing.double);
      expect(DartSector.parse('d10').face, 10);
      expect(DartSector.parse('T19').ring, DartRing.triple);
      expect(DartSector.parse('t19').face, 19);
    });

    test('parses both bull rings', () {
      expect(DartSector.parse('Bull').ring, DartRing.bull);
      expect(DartSector.parse('25').ring, DartRing.ring25);
      expect(DartSector.parse('Outer Bull').ring, DartRing.ring25);
    });

    test('there is no double bull — DBull and SBull are not sectors', () {
      // The board's grammar is ([SsDT])(1-20) | 25 | Bull | None. Code that
      // branches on DBull/SBull is branching on something that cannot arrive.
      expect(DartSector.parse('DBull').isMiss, isTrue);
      expect(DartSector.parse('SBull').isMiss, isTrue);
    });

    test('treats every flavour of nothing as a miss', () {
      for (final raw in ['Miss', 'None', '', '   ', null]) {
        expect(DartSector.parse(raw).isMiss, isTrue, reason: 'input: $raw');
      }
    });

    test('unrecognised input is a miss rather than an exception', () {
      // The previous implementations returned null here and every caller
      // treated null as a miss; a garbled report must never crash a turn.
      for (final raw in ['X20', 'S', '20', 'S99', 'S0', 'abc', 'T-4']) {
        expect(DartSector.parse(raw).isMiss, isTrue, reason: 'input: $raw');
      }
    });

    test('keeps the raw string for logging', () {
      expect(DartSector.parse('d10').raw, 'd10');
    });
  });

  group('scoring', () {
    test('score is face times factor', () {
      expect(DartSector.parse('S20').score, 20);
      expect(DartSector.parse('D20').score, 40);
      expect(DartSector.parse('T20').score, 60);
      expect(DartSector.parse('T19').score, 57);
      expect(DartSector.parse('Miss').score, 0);
    });

    test('bulls score 50 and 25', () {
      expect(DartSector.parse('Bull').score, 50);
      expect(DartSector.parse('25').score, 25);
    });

    test('factor matches the ring', () {
      expect(DartSector.parse('Miss').factor, 0);
      expect(DartSector.parse('S5').factor, 1);
      expect(DartSector.parse('25').factor, 1);
      expect(DartSector.parse('D5').factor, 2);
      expect(DartSector.parse('Bull').factor, 1,
          reason: 'The bullseye is a single landing worth 50 — it is not a '
              'double of anything, and there is no double bull');
      expect(DartSector.parse('T5').factor, 3);
    });
  });

  group('legacy adapters', () {
    test('legacyNumber keeps the shape games stored before', () {
      expect(DartSector.parse('Bull').legacyNumber, 50);
      expect(DartSector.parse('25').legacyNumber, 25);
      expect(DartSector.parse('T19').legacyNumber, 19);
      expect(DartSector.parse('Miss').legacyNumber, 0);
    });

    test('multiplierName reports both bulls as single', () {
      expect(DartSector.parse('Bull').multiplierName, 'single');
      expect(DartSector.parse('25').multiplierName, 'single');
      expect(DartSector.parse('S1').multiplierName, 'single');
      expect(DartSector.parse('D1').multiplierName, 'double');
      expect(DartSector.parse('T1').multiplierName, 'triple');
      expect(DartSector.parse('None').multiplierName, 'miss');
    });
  });

  group('display', () {
    test('label is canonical, not the raw input', () {
      expect(DartSector.parse('s20').label, 'S20');
      expect(DartSector.parse('DBull').label, 'Miss');
      expect(DartSector.parse('Outer Bull').label, '25');
      expect(DartSector.parse('None').label, 'Miss');
      expect(DartSector.parse('').label, 'Miss');
    });
  });

  group('equality', () {
    test('two parses of the same landing are equal regardless of casing', () {
      expect(DartSector.parse('t19'), DartSector.parse('T19'));
      expect(DartSector.parse('BULL'), DartSector.parse('bull'));
      expect(DartSector.parse('Bull'), isNot(DartSector.parse('25')),
          reason: 'The bullseye (50) and the 25 ring are different landings');
      expect(DartSector.parse('S20'), isNot(DartSector.parse('D20')));
      expect(DartSector.parse('Bull'), isNot(DartSector.parse('25')));
    });
  });
}
