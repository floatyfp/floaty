import 'package:flutter/material.dart';

const int nameColorCount = 10;

const List<String> liveChatUsernameColors = [
  '#aaaaaa',
  '#006699',
  '#cc6600',
  '#d400d4',
  '#009933',
  '#ff6600',
  '#006666',
  '#b63d3d',
  '#9763cb',
  '#0099cc',
];

int getUsernameColorIndex(String username) {
  final usernameHash = fastHashStringToInt(username);
  return (usernameHash % nameColorCount) + 1;
}

const int _maxSafeInteger = 9007199254740991;

int fastHashStringToInt(String str) {
  BigInt hashCode = BigInt.zero;

  for (var i = 0; i < str.length; i++) {
    final codeUnit = str.codeUnitAt(i);
    hashCode = BigInt.from(codeUnit) + ((hashCode << 5) - hashCode);
  }

  BigInt safeHashCode = hashCode % BigInt.from(_maxSafeInteger);

  if (safeHashCode.bitLength > 63) {
    throw RangeError('Hash value exceeds the range of an int');
  }

  return safeHashCode.toInt();
}

String getColorForUsername(String username) {
  int colorIndex = getUsernameColorIndex(username);
  return liveChatUsernameColors[colorIndex - 1];
}

Color getColorForUsernameColor(String username) {
  int colorIndex = getUsernameColorIndex(username);
  String colorHex = liveChatUsernameColors[colorIndex - 1];
  Color color = Color(int.parse('0xFF$colorHex'.replaceAll('#', '')));
  return color;
}
