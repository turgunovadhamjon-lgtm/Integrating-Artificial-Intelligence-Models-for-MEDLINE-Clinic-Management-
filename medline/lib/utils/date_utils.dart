// lib/utils/app_date_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AppDateUtils {
  static String formatTimestamp(
      Timestamp? timestamp,
      BuildContext context, {
        bool includeTime = true,
        bool smartToday = true,
      }) {
    if (timestamp == null) {
      return Provider.of<LanguageProvider>(context, listen: false)
          .translate('not_specified');
    }

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (smartToday && dateOnly == today) {
      return '${lang.translate('today')} ${DateFormat('HH:mm').format(date)}';
    } else if (smartToday && dateOnly == yesterday) {
      return '${lang.translate('yesterday')} ${DateFormat('HH:mm').format(date)}';
    } else {
      final pattern = lang.currentLanguage == 'ENG'
          ? (includeTime ? 'MMMM dd, yyyy, hh:mm a' : 'MMMM dd, yyyy')
          : (includeTime ? 'dd MMMM yyyy, HH:mm' : 'dd MMMM yyyy');
      return DateFormat(pattern).format(date);
    }
  }
}