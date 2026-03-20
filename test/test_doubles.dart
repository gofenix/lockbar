import 'package:lockbar/src/models/lockbar_models.dart';
import 'package:lockbar/src/platform/lockbar_platform.dart';
import 'package:lockbar/src/services/launch_at_startup_service.dart';
import 'package:lockbar/src/services/locale_preferences_service.dart';
import 'dart:ui';

class FakeLockbarPlatform implements LockbarPlatform {
  PermissionState permissionState = PermissionState.notDetermined;
  PermissionRequestResult permissionRequestResult =
      PermissionRequestResult.denied;
  LockResult lockResult = const LockResult(status: LockResultStatus.success);
  AppInfo info = const AppInfo(
    name: 'LockBar',
    version: '1.0.0',
    buildNumber: '1',
  );

  int requestPermissionCalls = 0;
  int lockCalls = 0;
  int openSettingsCalls = 0;
  int activateAppCalls = 0;
  int quitAppCalls = 0;
  String? lastNativeLocaleTag;

  @override
  Future<void> activateApp() async {
    activateAppCalls += 1;
  }

  @override
  Future<AppInfo> getAppInfo() async => info;

  @override
  Future<PermissionState> getPermissionState() async => permissionState;

  @override
  Future<LockResult> lockNow() async {
    lockCalls += 1;
    return lockResult;
  }

  @override
  Future<void> openAccessibilitySettings() async {
    openSettingsCalls += 1;
  }

  @override
  Future<void> quitApp() async {
    quitAppCalls += 1;
  }

  @override
  Future<PermissionRequestResult> requestPermission() async {
    requestPermissionCalls += 1;
    if (permissionRequestResult == PermissionRequestResult.granted) {
      permissionState = PermissionState.granted;
    } else if (permissionState != PermissionState.granted) {
      permissionState = PermissionState.denied;
    }
    return permissionRequestResult;
  }

  @override
  Future<void> setNativeLocale(Locale locale) async {
    lastNativeLocaleTag = locale.toLanguageTag();
  }
}

class FakeLaunchAtStartupService implements LaunchAtStartupService {
  bool enabled = false;
  int setEnabledCalls = 0;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCalls += 1;
    this.enabled = enabled;
  }
}

class FakeLocalePreferencesService implements LocalePreferencesService {
  FakeLocalePreferencesService({this.preference = AppLocalePreference.system});

  AppLocalePreference preference;
  int saveCalls = 0;

  @override
  Future<AppLocalePreference> loadPreference() async => preference;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {
    saveCalls += 1;
    this.preference = preference;
  }
}
