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

  group('Barrett Reduction', () {
    test('Computation', () {
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

    test('Reduce Polynomial', () {});
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
