import 'package:value/value.dart';

void main() {
  const presentVal = Val('Hello');
  const absentVal = Val<String>.absent();
  const clearVal = Val<String?>.clear();

  print('presentVal: ${presentVal('Default')}'); // Hello
  print('absentVal: ${absentVal('Default')}'); // Default
  print('clearVal: ${clearVal('Default')}'); // null
  print('extension: ${'test'.asVal}'); // Val(test)
}
