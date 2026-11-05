import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const small = 12.0;
  static const button = 16.0;
  static const card = 28.0;
  static const sheet = 32.0;
  static const pill = 100.0;
  static const cardBorder = BorderRadius.all(Radius.circular(card));
  static const buttonBorder = BorderRadius.all(Radius.circular(button));
  static const sheetBorder = BorderRadius.vertical(top: Radius.circular(sheet));
}
