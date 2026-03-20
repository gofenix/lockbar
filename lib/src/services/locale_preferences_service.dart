import 'package:shared_preferences/shared_preferences.dart';

import '../models/lockbar_models.dart';

abstract class LocalePreferencesService {
  Future<AppLocalePreference> loadPreference();

  Future<void> savePreference(AppLocalePreference preference);
}

class SharedPreferencesLocalePreferencesService
    implements LocalePreferencesService {
  SharedPreferencesLocalePreferencesService();

  static const _preferenceKey = 'lockbar.localePreference';

  @override
  Future<AppLocalePreference> loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    return AppLocalePreference.fromStorage(
      preferences.getString(_preferenceKey),
    );
  }

  @override
  Future<void> savePreference(AppLocalePreference preference) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, preference.storageValue);
  }
}
