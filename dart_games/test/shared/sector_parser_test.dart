import 'package:flutter_test/flutter_test.dart';
import 'sector_parser.dart';

void main() {
  group('SectorParser', () {
    group('parse()', () {
      test('parses singles correctly', () {
        expect(SectorParser.parse('S20'), {'number': 20, 'multiplier': 'single'});
        expect(SectorParser.parse('S1'), {'number': 1, 'multiplier': 'single'});
        expect(SectorParser.parse('s15'), {'number': 15, 'multiplier': 'single'});
      });

      test('parses doubles correctly', () {
        expect(SectorParser.parse('D20'), {'number': 20, 'multiplier': 'double'});
        expect(SectorParser.parse('d10'), {'number': 10, 'multiplier': 'double'});
      });

      test('parses triples correctly', () {
        expect(SectorParser.parse('T20'), {'number': 20, 'multiplier': 'triple'});
        expect(SectorParser.parse('t19'), {'number': 19, 'multiplier': 'triple'});
      });

      test('parses bullseye correctly', () {
        expect(SectorParser.parse('Bull'), {'number': 50, 'multiplier': 'single'});
      });

      test('parses outer bull correctly', () {
        expect(SectorParser.parse('25'), {'number': 25, 'multiplier': 'single'});
        expect(SectorParser.parse('Outer Bull'), {'number': 25, 'multiplier': 'single'});
      });

      test('parses miss correctly', () {
        expect(SectorParser.parse('Miss'), {'number': 0, 'multiplier': 'miss'});
        expect(SectorParser.parse('None'), {'number': 0, 'multiplier': 'miss'});
        expect(SectorParser.parse(''), {'number': 0, 'multiplier': 'miss'});
      });

      test('returns null for invalid input', () {
        expect(SectorParser.parse('X20'), null);
        expect(SectorParser.parse('20'), null);
        expect(SectorParser.parse('invalid'), null);
      });
    });

    group('getScore()', () {
      test('calculates single scores', () {
        expect(SectorParser.getScore('S20'), 20);
        expect(SectorParser.getScore('S1'), 1);
      });

      test('calculates double scores', () {
        expect(SectorParser.getScore('D20'), 40);
        expect(SectorParser.getScore('D10'), 20);
      });

      test('calculates triple scores', () {
        expect(SectorParser.getScore('T20'), 60);
        expect(SectorParser.getScore('T19'), 57);
      });

      test('handles special cases', () {
        expect(SectorParser.getScore('Bull'), 50);
        expect(SectorParser.getScore('25'), 25);
        expect(SectorParser.getScore('Miss'), 0);
      });
    });

    group('toCarnivalDerbyFormat()', () {
      test('converts regular sectors', () {
        expect(
          SectorParser.toCarnivalDerbyFormat('S20'),
          {'score': 20, 'multiplier': 'single'},
        );
        expect(
          SectorParser.toCarnivalDerbyFormat('D20'),
          {'score': 40, 'multiplier': 'double'},
        );
      });

      test('handles bullseye specially', () {
        expect(
          SectorParser.toCarnivalDerbyFormat('Bull'),
          {'score': 50, 'multiplier': 'bullseye'},
        );
      });

      test('returns null for invalid input', () {
        expect(SectorParser.toCarnivalDerbyFormat('invalid'), null);
      });
    });
  });
}
