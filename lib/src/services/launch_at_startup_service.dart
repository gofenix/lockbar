import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';

abstract class LaunchAtStartupService {
  Future<bool> isEnabled();

  Future<void> setEnabled(bool enabled);
}

class PluginLaunchAtStartupService implements LaunchAtStartupService {
  PluginLaunchAtStartupService() {
    launchAtStartup.setup(
      appName: 'LockBar',
      appPath: Platform.resolvedExecutable,
    );
  }

  @override
  Future<bool> isEnabled() {
    return launchAtStartup.isEnabled();
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}
