// ignore_for_file: constant_identifier_names

import 'package:enum_parser/enum_parser.dart';
import 'package:test/test.dart';

enum Status { pendingPayment, inProgress, completed, failed }

enum SimpleStatus { idle, running, finished, errorState }

void main() {
  group('EnumParserMode', () {
    test('getters return correct boolean flags', () {
      expect(EnumParserMode.strict.isStrict, isTrue);
      expect(EnumParserMode.strict.isSimple, isFalse);
      expect(EnumParserMode.strict.isLoose, isFalse);

      expect(EnumParserMode.simple.isStrict, isFalse);
      expect(EnumParserMode.simple.isSimple, isTrue);
      expect(EnumParserMode.simple.isLoose, isFalse);

      expect(EnumParserMode.loose.isStrict, isFalse);
      expect(EnumParserMode.loose.isSimple, isFalse);
      expect(EnumParserMode.loose.isLoose, isTrue);
    });
  });

  group('EnumParser.parse', () {
    test('returns direct instance immediately if src is already T', () {
      expect(
        EnumParser.parse<Status>(Status.completed, values: Status.values),
        equals(Status.completed),
      );
    });

    test('returns fallback when src is null or values is empty', () {
      expect(
        EnumParser.parse<Status>(
          null,
          values: Status.values,
          fallback: Status.failed,
        ),
        equals(Status.failed),
      );
      expect(
        EnumParser.parse<Status>(
          'pendingPayment',
          values: const [],
          fallback: Status.failed,
        ),
        equals(Status.failed),
      );
    });

    test('invokes custom converter when no match is found', () {
      final result = EnumParser.parse<Status>(
        'custom_key',
        values: Status.values,
        converter: (src, values) =>
            src == 'custom_key' ? Status.inProgress : null,
      );
      expect(result, equals(Status.inProgress));
    });

    test('returns fallback if converter yields null', () {
      final result = EnumParser.parse<Status>(
        'unknown',
        values: Status.values,
        converter: (src, values) => null,
        fallback: Status.failed,
      );
      expect(result, equals(Status.failed));
    });
  });

  group('EnumParserMode.strict', () {
    test('matches exact name', () {
      expect(
        EnumParser.parseStrict('pendingPayment', values: Status.values),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parse<Status>(
          'pendingPayment',
          values: Status.values,
          mode: EnumParserMode.strict,
        ),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parseStrict('pending_payment', values: Status.values),
        isNull,
      );
      expect(
        EnumParser.parseStrict('PENDINGPAYMENT', values: Status.values),
        isNull,
      );
      expect(
        EnumParser.parseStrict('Status.pendingPayment', values: Status.values),
        isNull,
      );
    });

    test('does not match numeric inputs in strict mode', () {
      expect(EnumParser.parseStrict(1, values: Status.values), isNull);
      expect(EnumParser.parseStrict('1', values: Status.values), isNull);
    });

    test('supports another Enum input with matching name', () {
      expect(
        EnumParser.parseStrict(
          SimpleStatus.idle,
          values: [Status.pendingPayment],
        ),
        isNull,
      );
    });
  });

  group('EnumParserMode.simple', () {
    test('matches case-insensitively with outer whitespace trimmed', () {
      expect(
        EnumParser.parseSimple('PENDINGPAYMENT', values: Status.values),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parseSimple('  inprogress  ', values: Status.values),
        equals(Status.inProgress),
      );
    });

    test('does not strip delimiters or prefixes in simple mode', () {
      expect(
        EnumParser.parseSimple('pending_payment', values: Status.values),
        isNull,
      );
      expect(
        EnumParser.parseSimple('Status.completed', values: Status.values),
        isNull,
      );
    });
  });

  group('EnumParserMode.loose', () {
    test('normalizes spaces, underscores, hyphens and case', () {
      expect(
        EnumParser.parseLoose('pending_payment', values: Status.values),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parseLoose('pending-payment', values: Status.values),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parseLoose('PENDING PAYMENT', values: Status.values),
        equals(Status.pendingPayment),
      );
    });

    test('strips class and enum type prefixes', () {
      expect(
        EnumParser.parseLoose('Status.completed', values: Status.values),
        equals(Status.completed),
      );
      expect(
        EnumParser.parseLoose('MyModule.Status.failed', values: Status.values),
        equals(Status.failed),
      );
      expect(
        EnumParser.parseLoose(
          'SimpleStatus.errorState',
          values: SimpleStatus.values,
        ),
        equals(SimpleStatus.errorState),
      );
    });

    test('handles unicode whitespace and delimiters', () {
      expect(
        EnumParser.parseLoose('in\u00A0progress', values: Status.values),
        equals(Status.inProgress),
      );
    });
  });

  group('EnumParser.parseList', () {
    test('throws ArgumentError on empty separator', () {
      expect(
        () => EnumParser.parseList('a,b', values: Status.values, separator: ''),
        throwsArgumentError,
      );
    });

    test('fast path: returns typed List<T> or converts Iterable<T>', () {
      final list = [Status.pendingPayment, Status.inProgress];
      expect(
        EnumParser.parseList<Status>(list, values: Status.values),
        same(list),
      );

      final iterable = Status.values.take(2);
      final parsed = EnumParser.parseList<Status>(
        iterable,
        values: Status.values,
      );
      expect(parsed, equals([Status.pendingPayment, Status.inProgress]));
    });

    test('parses comma-separated strings across modes', () {
      final looseList = EnumParser.parseListLoose(
        'pending_payment, in-progress, Status.completed',
        values: Status.values,
      );
      expect(
        looseList,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );

      final strictList = EnumParser.parseListStrict(
        'pendingPayment,inProgress,completed',
        values: Status.values,
      );
      expect(
        strictList,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );

      final simpleList = EnumParser.parseListSimple(
        'PENDINGPAYMENT, INPROGRESS',
        values: Status.values,
      );
      expect(simpleList, equals([Status.pendingPayment, Status.inProgress]));
    });

    test('handles single-item, small-batch, and large-batch optimizations', () {
      // 1 item
      final one = EnumParser.parseList(
        'pending_payment',
        values: Status.values,
      );
      expect(one, equals([Status.pendingPayment]));

      // 3 items (<= 4 items)
      final three = EnumParser.parseList([
        'pending_payment',
        'in-progress',
        Status.completed,
      ], values: Status.values);
      expect(
        three,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );

      // > 4 items (large batch)
      final large = EnumParser.parseList([
        'pending_payment',
        'in-progress',
        'completed',
        'failed',
        'pendingPayment',
        'unknown',
      ], values: Status.values);
      expect(
        large,
        equals([
          Status.pendingPayment,
          Status.inProgress,
          Status.completed,
          Status.failed,
          Status.pendingPayment,
        ]),
      );
    });

    test('returns fallback if no items could be matched', () {
      expect(
        EnumParser.parseList(
          'unknown1, unknown2',
          values: Status.values,
          fallback: [Status.failed],
        ),
        equals([Status.failed]),
      );
      expect(
        EnumParser.parseList(
          null,
          values: Status.values,
          fallback: [Status.failed],
        ),
        equals([Status.failed]),
      );
    });
  });

  group('EnumIndex', () {
    test('pre-computes lookups and parses in O(1)', () {
      final index = Status.values.toEnumIndex(mode: EnumParserMode.loose);
      expect(index.parse('pending_payment'), equals(Status.pendingPayment));
      expect(index.parse('Status.inProgress'), equals(Status.inProgress));
      expect(index.parse('completed'), equals(Status.completed));
      expect(index.parse('failed'), equals(Status.failed));
      expect(index.parse('unknown'), isNull);
    });

    test('supports strict and simple modes in EnumIndex', () {
      final strictIndex = Status.values.toEnumIndex(
        mode: EnumParserMode.strict,
      );
      expect(
        strictIndex.parse('pendingPayment'),
        equals(Status.pendingPayment),
      );
      expect(strictIndex.parse('pending_payment'), isNull);

      final simpleIndex = Status.values.toEnumIndex(
        mode: EnumParserMode.simple,
      );
      expect(
        simpleIndex.parse('PENDINGPAYMENT'),
        equals(Status.pendingPayment),
      );
      expect(simpleIndex.parse('pending_payment'), isNull);
    });

    test('EnumIndex.parseList resolves multiple items efficiently', () {
      final index = Status.values.toEnumIndex(mode: EnumParserMode.loose);
      final list = index.parseList(
        'pending_payment, in-progress, Status.completed',
      );
      expect(
        list,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );
    });

    test('EnumParser.index constructor creates an EnumIndex', () {
      final index = EnumParser.index(Status.values);
      expect(index.parse('completed'), equals(Status.completed));
    });
  });

  group('EnumParserX extensions', () {
    test('provides fluent parsing methods directly on Iterable<Enum>', () {
      expect(
        Status.values.parse('pending_payment'),
        equals(Status.pendingPayment),
      );
      expect(
        Status.values.parseStrict('inProgress'),
        equals(Status.inProgress),
      );
      expect(Status.values.parseSimple('COMPLETED'), equals(Status.completed));
      expect(Status.values.parseLoose('Status.failed'), equals(Status.failed));
    });

    test('provides fluent list parsing methods on Iterable<Enum>', () {
      expect(
        Status.values.parseList('pendingPayment, inProgress'),
        equals([Status.pendingPayment, Status.inProgress]),
      );
      expect(
        Status.values.parseListStrict('pendingPayment,inProgress'),
        equals([Status.pendingPayment, Status.inProgress]),
      );
      expect(
        Status.values.parseListSimple('PENDINGPAYMENT, INPROGRESS'),
        equals([Status.pendingPayment, Status.inProgress]),
      );
      expect(
        Status.values.parseListLoose('pending_payment, in-progress'),
        equals([Status.pendingPayment, Status.inProgress]),
      );
    });
  });

  group('Enum-to-Enum Mapping', () {
    test('maps SCREAMING_SNAKE_CASE source enum to camelCase target enum', () {
      expect(
        Status.values.parse(SourceStatus.PENDING_PAYMENT),
        equals(Status.pendingPayment),
      );
      expect(
        Status.values.parse(SourceStatus.IN_PROGRESS),
        equals(Status.inProgress),
      );
      expect(
        Status.values.parse(SourceStatus.COMPLETED),
        equals(Status.completed),
      );
      expect(Status.values.parse(SourceStatus.FAILED), equals(Status.failed));
    });

    test('batch maps List of source enums to target enums', () {
      final sourceList = [
        SourceStatus.PENDING_PAYMENT,
        SourceStatus.IN_PROGRESS,
        SourceStatus.FAILED,
      ];
      final targetList = Status.values.parseList(sourceList);
      expect(
        targetList,
        equals([Status.pendingPayment, Status.inProgress, Status.failed]),
      );
    });

    test('maps source enum via EnumIndex in O(1)', () {
      final index = Status.values.toEnumIndex(mode: EnumParserMode.loose);
      expect(index.parse(SourceStatus.COMPLETED), equals(Status.completed));
    });

    test('maps between enums with identical member names in strict mode', () {
      expect(
        SimpleStatus.values.parseStrict(OtherStatus.idle),
        equals(SimpleStatus.idle),
      );
    });
  });

  group('Normalization Collisions & Deterministic Resolution', () {
    test('linear scan, EnumIndex, and parseList deterministically pick first match', () {
      // 1. Linear scalar parse
      final linearMatch = EnumParser.parseLoose(
        'foo-bar',
        values: CollidingEnum.values,
      );
      expect(linearMatch, equals(CollidingEnum.fooBar));

      // 2. EnumIndex pre-indexed lookup
      final index = CollidingEnum.values.toEnumIndex(
        mode: EnumParserMode.loose,
      );
      expect(index.parse('foo-bar'), equals(CollidingEnum.fooBar));

      // 3. parseList small batch (<= 4 items)
      final smallBatch = EnumParser.parseList([
        'foo-bar',
        'other',
      ], values: CollidingEnum.values);
      expect(smallBatch.first, equals(CollidingEnum.fooBar));

      // 4. parseList large batch (> 4 items)
      final largeBatch = EnumParser.parseList([
        'foo-bar',
        'other',
        'other',
        'other',
        'other',
      ], values: CollidingEnum.values);
      expect(largeBatch.first, equals(CollidingEnum.fooBar));
    });
  });

  group('EnumIndex Immutability & Snapshots', () {
    test('isolates index from mutations to original source list', () {
      final mutableSource = [Status.pendingPayment, Status.inProgress];
      final index = EnumIndex(mutableSource, mode: EnumParserMode.loose);

      // Mutate the original source
      mutableSource.clear();

      // Index values must remain intact as an unmodifiable snapshot
      expect(index.values.length, equals(2));
      expect(index.values, equals([Status.pendingPayment, Status.inProgress]));
      expect(index.parse('in-progress'), equals(Status.inProgress));

      // Attempting to mutate index.values must throw
      expect(
        () => (index.values as dynamic).add(Status.completed),
        throwsUnsupportedError,
      );
    });
  });

  group('Delimiter-Only and Boundary Inputs', () {
    test('delimiter-only inputs return fallback and do not match enums', () {
      for (final delimiter in ['-', '_', '--', '__', '...', '   ', '\u00A0']) {
        expect(
          EnumParser.parseLoose(delimiter, values: Status.values),
          isNull,
          reason: 'Delimiter "$delimiter" should not resolve to an enum',
        );
        expect(
          Status.values.toEnumIndex().parse(delimiter),
          isNull,
          reason: 'Delimiter "$delimiter" should not resolve in EnumIndex',
        );
      }
    });

    test('supports multi-character separators', () {
      final parsed = EnumParser.parseList(
        'pending_payment::in-progress::completed',
        values: Status.values,
        separator: '::',
      );
      expect(
        parsed,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );
    });

    test(
      'returns ungrowable list consistently across 1 item and multi-item paths',
      () {
        final one = EnumParser.parseList(
          'pending_payment',
          values: Status.values,
        );
        final multi = EnumParser.parseList(
          'pending_payment, in_progress',
          values: Status.values,
        );
        final large = EnumParser.parseList(
          'pending_payment, in_progress, completed, failed, pending_payment',
          values: Status.values,
        );

        expect(() => one.add(Status.failed), throwsUnsupportedError);
        expect(() => multi.add(Status.failed), throwsUnsupportedError);
        expect(() => large.add(Status.failed), throwsUnsupportedError);
      },
    );
  });

  group('Unicode & Non-ASCII Delimiter Edge Cases', () {
    test('matches diverse Unicode whitespace and delimiters properly', () {
      expect(
        EnumParser.parseLoose('pending\u2000payment', values: Status.values),
        equals(Status.pendingPayment),
      );
      expect(
        EnumParser.parseLoose('in\u2003progress', values: Status.values),
        equals(Status.inProgress),
      );
      expect(
        EnumParser.parseLoose('completed\u3000', values: Status.values),
        equals(Status.completed),
      );
      expect(
        Status.values.toEnumIndex().parse('pending\u202Fpayment'),
        equals(Status.pendingPayment),
      );
    });

    test('direct and indexed parsing yield identical results for unicode delimiter inputs', () {
      final inputs = [
        'pending\u00A0payment',
        'in\u2000progress',
        'in\u2003progress',
        'completed\u3000',
        'failed\uFEFF',
        'unknown\u205Fitem',
      ];
      final index = Status.values.toEnumIndex();

      for (final input in inputs) {
        final direct = EnumParser.parseLoose(input, values: Status.values);
        final indexed = index.parse(input);
        expect(
          direct,
          equals(indexed),
          reason: 'Mismatch between direct and indexed parsing on "$input"',
        );
      }
    });
  });

  group('Equivalence Between Direct and Indexed Parsing', () {
    test('all modes return equivalent results across diverse queries', () {
      final queries = [
        'pendingPayment',
        'pending_payment',
        'PENDING PAYMENT',
        'Status.completed',
        'failed',
        'unknown_item',
        '',
        '   ',
        '---',
      ];

      for (final mode in EnumParserMode.values) {
        final index = Status.values.toEnumIndex(mode: mode);
        for (final q in queries) {
          final direct = EnumParser.parse(q, values: Status.values, mode: mode);
          final indexed = index.parse(q);
          expect(
            direct,
            equals(indexed),
            reason: 'Mode $mode mismatch for query "$q"',
          );
        }
      }
    });

    test(
      'parseList returns identical results between linear and indexed paths',
      () {
        // Test lists spanning <= 16 and > 16 items
        final batch10 = [
          'pending_payment',
          'in-progress',
          'completed',
          'failed',
          'unknown',
          'Status.pendingPayment',
          'IN_PROGRESS',
          'completed',
          'failed',
          'missing',
        ];
        final batch20 = [...batch10, ...batch10];

        final linear10 = EnumParser.parseList(batch10, values: Status.values);
        final indexed10 = Status.values.toEnumIndex().parseList(batch10);
        expect(linear10, equals(indexed10));

        final linear20 = EnumParser.parseList(batch20, values: Status.values);
        final indexed20 = Status.values.toEnumIndex().parseList(batch20);
        expect(linear20, equals(indexed20));
      },
    );
  });
}

enum CollidingEnum { fooBar, foo_bar, other }

enum SourceStatus { PENDING_PAYMENT, IN_PROGRESS, COMPLETED, FAILED }

enum OtherStatus { idle, running }
