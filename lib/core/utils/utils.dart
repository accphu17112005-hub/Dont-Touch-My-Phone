import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtils {
  HashUtils._();

  /// Hash a PIN using SHA-256 with salt
  static String hashPin(String pin) {
    final salt = 'dont_touch_my_phone_salt_v1';
    final bytes = utf8.encode('$salt$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a PIN against a stored hash
  static bool verifyPin(String pin, String storedHash) {
    return hashPin(pin) == storedHash;
  }
}

class SensitivityUtils {
  SensitivityUtils._();

  static double sensitivityToThreshold(String sensitivity) {
    switch (sensitivity) {
      case 'low':
        return 3.5;
      case 'medium':
        return 2.0;
      case 'high':
        return 1.0;
      default:
        return 2.0;
    }
  }

  static String thresholdToSensitivity(double threshold) {
    if (threshold >= 3.0) return 'low';
    if (threshold >= 1.5) return 'medium';
    return 'high';
  }
}

class DateTimeUtils {
  DateTimeUtils._();

  static String formatDateTime(DateTime dt) {
    return '${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year} at ${_time(dt)}';
  }

  static String formatDate(DateTime dt) {
    return '${_weekday(dt.weekday)}, ${_month(dt.month)} ${dt.day}, ${dt.year}';
  }

  static String formatTime(DateTime dt) => _time(dt);

  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  static String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static String _weekday(int d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d - 1];
  }

  static String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
