import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:kyber/kyber.dart';

void main() async {
  group('Montgomery Reduction', () {
    test('Positive', () {
      var file = File('test/montgomery_reduce_positive.json');
      var content = file.readAsStringSync();
      var values = (jsonDecode(content)['values'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
      var failure = false;
      var fails = <int>[];
      for (int i = 0; i < values.length; i++) {
        if (values[i] != KyberFunctions.montgomeryReduce(i)) {
          failure = true;
          fails.add(i);
        }
      }
      if (failure) {
        _log('FAILURES :: $fails', _ConsoleColors.red);
      }
      expect(failure, false);
    });
    test('Negative', () {
      var file = File('test/montgomery_reduce_negative.json');
      var content = file.readAsStringSync();
      var values = (jsonDecode(content)['values'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
      bool failure = false;
      var fails = <int>[];
      for (int i = -values.length; i > 0; i++) {
        if (values[values.length + i] != KyberFunctions.montgomeryReduce(i)) {
          failure = true;
          fails.add(i);
        }
      }
      if (failure) {
        _log('FAILURES :: $fails', _ConsoleColors.red);
      }
      expect(failure, false);
    });
  });

  test('Barrett Reduction', () {
    var file = File('test/barrett_computation.json');
    var contents = file.readAsStringSync();
    var values = (jsonDecode(contents)['values'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    var failure = false;
    var fails = <int>[];
    for (int i = 0; i < 100000; i++) {
      if (values[i] != NTT.computeBarret(i)) {
        failure = true;
        fails.add(i);
      }
    }
    if (failure) {
      _log('FAILURES :: $fails', _ConsoleColors.red);
    }
    expect(failure, false);
  });

  group('Bit Shift', () {
    var file = File('test/bitshift.json');
    var contents = file.readAsStringSync();
    var lsValues = (jsonDecode(contents)['leftShift'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    var rsValues = (jsonDecode(contents)['rightShift'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    var tsValues = (jsonDecode(contents)['tripleShift'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    test('Left', () {
      bool failure = false;
      List<int> fails = [];
      for (int i = 0; i < 100000; i++) {
        int number = i << 1;
        if (number != lsValues[i]) {
          failure = true;
          fails.add(i);
        }
      }
      if (failure) {
        _log('FAILURES :: $fails', _ConsoleColors.red);
      }
      expect(failure, false);
    });

    test('Right', () {
      bool failure = false;
      List<int> fails = [];
      for (int i = 0; i < 100000; i++) {
        int number = i >> 1;
        if (number != rsValues[i]) {
          failure = true;
          fails.add(i);
        }
      }
      if (failure) {
        _log('FAILURES :: $fails', _ConsoleColors.red);
      }
      expect(failure, false);
    });

    test('Triple', () {
      bool failure = false;
      List<int> fails = [];
      for (int i = 0; i < 100000; i++) {
        int number = i >>> 1;
        if (number != tsValues[i]) {
          failure = true;
          fails.add(i);
        }
      }
      if (failure) {
        _log('FAILURES :: $fails', _ConsoleColors.red);
      }
      expect(failure, false);
    });
  });

  group('Number Theoretic Transform', () {
    var file = File('test/ntt_results.json');
    var content = file.readAsStringSync();
    var nttSample = (jsonDecode(content)['ntt'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    var nttInverseSample = (jsonDecode(content)['nttInverse'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    List<int> candidate = [];
    for (int i = 0; i < 256; i++) {
      candidate.add(i);
    }

    var nttResult = <int>[];
    test('Forward', () {
      nttResult = NTT.doTransform(candidate);
      var forwardFailure = false;
      var forwardFails = <int>[];
      for (int i = 0; i < nttResult.length; i++) {
        if (nttResult[i] != nttSample[i]) {
          forwardFailure = true;
          forwardFails.add(i);
        }
      }
      if (forwardFailure) {
        _log('FAILURES :: $forwardFails', _ConsoleColors.red);
      }
      expect(forwardFailure, false);
    });

    test('Inverse', () {
      var nttInverseResult = NTT.doInverse(nttResult);
      var inverseFailure = false;
      var inverseFails = <int>[];
      for (int i = 0; i < nttInverseResult.length; i++) {
        if (nttInverseResult[i] != nttInverseSample[i]) {
          inverseFailure = true;
          inverseFails.add(i);
        }
      }
      if (inverseFailure) {
        _log('FAILURES :: $inverseFails', _ConsoleColors.red);
      }
      expect(inverseFailure, false);
    });
  });
}

void _log(String text, _ConsoleColors? color) {
  print(_cColors[color ?? _ConsoleColors.normal]! +
      text +
      _cColors[_ConsoleColors.normal]!);
}

enum _ConsoleColors { red, green, normal }

Map<_ConsoleColors, String> _cColors = {
  _ConsoleColors.red: '\x1b[0;31m',
  _ConsoleColors.green: '\x1b[0;32m',
  _ConsoleColors.normal: '\x1b[0m',
};

extension _ByteConversion on String {
  ///
  List<int> toBytes() {
    if (length.isEven) {
      List<int> list = [];
      for (int i = 0; i < length; i += 2) {
        list.add(int.parse(substring(i, i + 2), radix: 16));
      }
      return list;
    } else {
      throw Exception('Invalid hex string');
    }
  }
}
