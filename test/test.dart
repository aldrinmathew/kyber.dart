import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:kyber/kyber.dart';

void main() async {
  group('Montgomery Reduction', () {
    test('Positive', () async {
      var file = File('test/montgomery_reduce_positive.json');
      var content = await file.readAsString();
      var values = (jsonDecode(content)['values'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
      bool failure = false;
      for (int i = 0; i < values.length; i++) {
        if (values[i] != KyberFunctions.montgomeryReduce(i)) {
          _log('FAIL :: $i', _ConsoleColors.red);
          failure = true;
        }
      }
      expect(failure, false);
    });
    test('Negative', () async {
      var file = File('test/montgomery_reduce_negative.json');
      var content = await file.readAsString();
      var values = (jsonDecode(content)['values'] as List<dynamic>)
          .map((e) => e as int)
          .toList();
      bool failure = false;
      for (int i = -values.length; i > 0; i++) {
        if (values[values.length + i] != KyberFunctions.montgomeryReduce(i)) {
          _log('FAIL :: $i', _ConsoleColors.red);
          failure = true;
        }
      }
      expect(failure, false);
    });
  });
}

void _log(String text, _ConsoleColors? color) {
  print(_cColors[color ?? _ConsoleColors.normal]! +
      text +
      _cColors[_ConsoleColors.normal]!);
}

enum _ConsoleColors { red, normal }

Map<_ConsoleColors, String> _cColors = {
  _ConsoleColors.red: '\x1b[0;31m',
  _ConsoleColors.normal: '\x1b[0m',
};
