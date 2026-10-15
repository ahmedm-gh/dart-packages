// ignore_for_file: constant_identifier_names

import 'package:enum_parser/enum_parser.dart';
import 'package:test/test.dart';

enum Status {
  pendingPayment,
  inProgress,
  completed,
  failed;
}

enum SimpleStatus {
  idle,
  running,
  finished,
  errorState,
}

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
        EnumParser.parseStrict(SimpleStatus.idle,
            values: [Status.pendingPayment]),
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
        EnumParser.parseLoose('SimpleStatus.errorState',
            values: SimpleStatus.values),
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
      expect(EnumParser.parseList<Status>(list, values: Status.values),
          same(list));

      final iterable = Status.values.take(2);
      final parsed =
          EnumParser.parseList<Status>(iterable, values: Status.values);
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
      final one =
          EnumParser.parseList('pending_payment', values: Status.values);
      expect(one, equals([Status.pendingPayment]));

      // 3 items (<= 4 items)
      final three = EnumParser.parseList(
        ['pending_payment', 'in-progress', Status.completed],
        values: Status.values,
      );
      expect(
        three,
        equals([Status.pendingPayment, Status.inProgress, Status.completed]),
      );

      // > 4 items (large batch)
      final large = EnumParser.parseList(
        [
          'pending_payment',
          'in-progress',
          'completed',
          'failed',
          'pendingPayment',
          'unknown'
        ],
        values: Status.values,
      );
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
      final strictIndex =
          Status.values.toEnumIndex(mode: EnumParserMode.strict);
      expect(
          strictIndex.parse('pendingPayment'), equals(Status.pendingPayment));
      expect(strictIndex.parse('pending_payment'), isNull);

      final simpleIndex =
          Status.values.toEnumIndex(mode: EnumParserMode.simple);
      expect(
          simpleIndex.parse('PENDINGPAYMENT'), equals(Status.pendingPayment));
      expect(simpleIndex.parse('pending_payment'), isNull);
    });

    test('EnumIndex.parseList resolves multiple items efficiently', () {
      final index = Status.values.toEnumIndex(mode: EnumParserMode.loose);
      final list =
          index.parseList('pending_payment, in-progress, Status.completed');
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
      expect(
        Status.values.parseSimple('COMPLETED'),
        equals(Status.completed),
      );
      expect(
        Status.values.parseLoose('Status.failed'),
        equals(Status.failed),
      );
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
      expect(
        Status.values.parse(SourceStatus.FAILED),
        equals(Status.failed),
      );
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
        equals([
          Status.pendingPayment,
          Status.inProgress,
          Status.failed,
        ]),
      );
    });

    test('maps source enum via EnumIndex in O(1)', () {
      final index = Status.values.toEnumIndex(mode: EnumParserMode.loose);
      expect(
        index.parse(SourceStatus.COMPLETED),
        equals(Status.completed),
      );
    });

    test('maps between enums with identical member names in strict mode', () {
      expect(
        SimpleStatus.values.parseStrict(OtherStatus.idle),
        equals(SimpleStatus.idle),
      );
    });
  });
}

enum SourceStatus {
  PENDING_PAYMENT,
  IN_PROGRESS,
  COMPLETED,
  FAILED,
}

enum OtherStatus {
  idle,
  running,
}
