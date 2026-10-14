import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the calendar day of the last login so the app can force a logout when
/// the day changes (distribution shifts are daily).
class SessionService {
  SessionService(this._prefs);

  final SharedPreferences _prefs;

  static const _kLoginDate = 'session_login_date';

  static String _dayKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// Records that a login happened today.
  Future<void> markLogin() => _prefs.setString(_kLoginDate, _dayKey());

  /// True when a previous login exists and it was on an earlier calendar day.
  bool shouldAutoLogout() {
    final stored = _prefs.getString(_kLoginDate);
    if (stored == null) return false;
    return stored != _dayKey();
  }

  Future<void> clear() => _prefs.remove(_kLoginDate);
}
