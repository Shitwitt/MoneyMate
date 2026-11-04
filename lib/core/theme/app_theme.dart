import 'package:flutter/material.dart';
import '../models/models.dart';
import 'theme.dart';
export 'theme.dart';

ThemeData buildTheme(AppSettings settings, Brightness brightness, {ColorScheme? dynamicScheme}) => tinkTheme(settings, brightness, dynamicScheme: dynamicScheme);
