import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart'; // ใช้ AppSettingsScope

/// ใช้ทั่วแอพ: formatDate(context, date, withTime: true/false)
String formatDate(
  BuildContext context,
  DateTime date, {
  bool withTime = false,
}) {
  final settings = AppSettingsScope.of(context);

  final pattern = settings.dateFormat; // dd-MM-yyyy / MM/dd/yyyy / yyyy-MM-dd
  final locale = settings.locale.toLanguageTag().replaceAll('-', '_'); // th_TH / en_US

  final dateText = DateFormat(pattern, locale).format(date);

  if (!withTime) return dateText;

  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$dateText $hh:$mm';
}
