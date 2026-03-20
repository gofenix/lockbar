// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get preparingLockBar => '正在准备 LockBar…';

  @override
  String get heroTitle => '一键锁屏，立即生效。';

  @override
  String get heroDescription => '左键点击菜单栏图标即可立即锁屏，右键点击可打开菜单并管理启动行为。';

  @override
  String get leftClickLocks => '左键立即锁屏';

  @override
  String get rightClickOpensMenu => '右键打开菜单';

  @override
  String get permissionGrantedTitle => '辅助功能权限已开启';

  @override
  String get permissionGrantedDescription =>
      'LockBar 现在可以在不打开完整主窗口的情况下，从菜单栏模拟 macOS 标准锁屏快捷键。';

  @override
  String get permissionDeniedTitle => '辅助功能权限仍未开启';

  @override
  String get permissionDeniedDescription =>
      '打开“系统设置”中的“隐私与安全性 > 辅助功能”，启用 LockBar，然后返回这里或再次点击菜单栏图标。如果刚授权后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get permissionNotDeterminedTitle => '需要先授予一次权限';

  @override
  String get permissionNotDeterminedDescription =>
      'LockBar 需要 macOS 的辅助功能权限，才能代你发送标准的 Control + Command + Q 锁屏快捷键。';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get requestPermission => '请求权限';

  @override
  String get openSystemSettings => '打开系统设置';

  @override
  String get controlsTitle => '控制项';

  @override
  String get launchAtLogin => '登录时启动';

  @override
  String get launchAtLoginDescription => '每次开机登录后，都让 LockBar 自动常驻在菜单栏。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageDescription => '选择让 LockBar 跟随系统语言，或使用手动覆盖的界面语言。';

  @override
  String get followSystem => '跟随系统';

  @override
  String get englishLanguageName => 'English';

  @override
  String get simplifiedChineseLanguageName => '简体中文';

  @override
  String currentLanguageLabel(Object language) {
    return '当前生效语言：$language';
  }

  @override
  String get lockNow => '立即锁屏';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutDescription =>
      '适用于 macOS 13 及以上版本。LockBar 只会使用系统辅助功能权限来模拟标准的 Control + Command + Q 锁屏快捷键。';

  @override
  String get openSettings => '打开设置';

  @override
  String get quitAction => '退出';

  @override
  String get statusTrayReady => '现在点击菜单栏图标，就可以立即锁定你的 Mac。';

  @override
  String get statusPermissionNeededOnce => '先授予一次辅助功能权限，之后 LockBar 就能一键锁屏。';

  @override
  String get statusStartupFailed =>
      'LockBar 启动时未能完成初始化。请重新打开应用，或检查 macOS 控制台中的原生日志。';

  @override
  String get statusPermissionGranted => '辅助功能权限已开启。LockBar 现在可以从菜单栏锁定你的 Mac。';

  @override
  String get statusPermissionRefreshFailed => 'LockBar 无法刷新当前的权限状态。';

  @override
  String get statusPermissionStillNeeded => 'LockBar 仍然需要辅助功能权限，才能执行锁屏。';

  @override
  String get statusTrayActionFailed => 'LockBar 无法完成这次菜单栏点击操作。';

  @override
  String get statusAccessibilityStillOff =>
      '辅助功能权限仍未开启。请先在系统设置中启用，然后再试一次。如果你刚刚完成授权但系统还没刷新，请退出并重新打开 LockBar。';

  @override
  String get statusLockServiceUnavailable => 'LockBar 无法连接到 macOS 锁屏服务。';

  @override
  String get statusOpenedSystemSettings =>
      '已打开系统设置。请在“隐私与安全性 > 辅助功能”中启用 LockBar。如果启用后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get statusOpenSystemSettingsFailed => 'LockBar 无法自动打开系统设置。';

  @override
  String get statusLaunchAtLoginEnabled => 'LockBar 现在会在你登录时自动启动。';

  @override
  String get statusLaunchAtLoginDisabled => '已关闭“登录时启动”。';

  @override
  String get statusLaunchAtLoginFailed => 'LockBar 无法更新登录启动设置。';

  @override
  String get statusPermissionGrantedClickTrayAgain =>
      '辅助功能权限已开启。再次点击菜单栏图标即可立即锁屏。';

  @override
  String get statusPermissionEnableThenRetry =>
      'LockBar 需要辅助功能权限才能锁屏。请先在系统设置中启用，然后再试一次。如果刚授权后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get statusLockCommandSent => '已发送锁屏指令。';

  @override
  String get statusLockFailureEventSource => 'LockBar 无法创建系统键盘事件源。';

  @override
  String get statusLockFailureEventSequence => 'LockBar 无法构建锁屏快捷键事件序列。';

  @override
  String get statusLockFailureGeneric => 'LockBar 无法触发系统锁屏快捷键。';

  @override
  String get statusLocalePreferenceFailed => 'LockBar 无法保存语言偏好设置。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get preparingLockBar => '正在准备 LockBar…';

  @override
  String get heroTitle => '一键锁屏，立即生效。';

  @override
  String get heroDescription => '左键点击菜单栏图标即可立即锁屏，右键点击可打开菜单并管理启动行为。';

  @override
  String get leftClickLocks => '左键立即锁屏';

  @override
  String get rightClickOpensMenu => '右键打开菜单';

  @override
  String get permissionGrantedTitle => '辅助功能权限已开启';

  @override
  String get permissionGrantedDescription =>
      'LockBar 现在可以在不打开完整主窗口的情况下，从菜单栏模拟 macOS 标准锁屏快捷键。';

  @override
  String get permissionDeniedTitle => '辅助功能权限仍未开启';

  @override
  String get permissionDeniedDescription =>
      '打开“系统设置”中的“隐私与安全性 > 辅助功能”，启用 LockBar，然后返回这里或再次点击菜单栏图标。如果刚授权后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get permissionNotDeterminedTitle => '需要先授予一次权限';

  @override
  String get permissionNotDeterminedDescription =>
      'LockBar 需要 macOS 的辅助功能权限，才能代你发送标准的 Control + Command + Q 锁屏快捷键。';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get requestPermission => '请求权限';

  @override
  String get openSystemSettings => '打开系统设置';

  @override
  String get controlsTitle => '控制项';

  @override
  String get launchAtLogin => '登录时启动';

  @override
  String get launchAtLoginDescription => '每次开机登录后，都让 LockBar 自动常驻在菜单栏。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageDescription => '选择让 LockBar 跟随系统语言，或使用手动覆盖的界面语言。';

  @override
  String get followSystem => '跟随系统';

  @override
  String get englishLanguageName => 'English';

  @override
  String get simplifiedChineseLanguageName => '简体中文';

  @override
  String currentLanguageLabel(Object language) {
    return '当前生效语言：$language';
  }

  @override
  String get lockNow => '立即锁屏';

  @override
  String get aboutTitle => '关于';

  @override
  String get aboutDescription =>
      '适用于 macOS 13 及以上版本。LockBar 只会使用系统辅助功能权限来模拟标准的 Control + Command + Q 锁屏快捷键。';

  @override
  String get openSettings => '打开设置';

  @override
  String get quitAction => '退出';

  @override
  String get statusTrayReady => '现在点击菜单栏图标，就可以立即锁定你的 Mac。';

  @override
  String get statusPermissionNeededOnce => '先授予一次辅助功能权限，之后 LockBar 就能一键锁屏。';

  @override
  String get statusStartupFailed =>
      'LockBar 启动时未能完成初始化。请重新打开应用，或检查 macOS 控制台中的原生日志。';

  @override
  String get statusPermissionGranted => '辅助功能权限已开启。LockBar 现在可以从菜单栏锁定你的 Mac。';

  @override
  String get statusPermissionRefreshFailed => 'LockBar 无法刷新当前的权限状态。';

  @override
  String get statusPermissionStillNeeded => 'LockBar 仍然需要辅助功能权限，才能执行锁屏。';

  @override
  String get statusTrayActionFailed => 'LockBar 无法完成这次菜单栏点击操作。';

  @override
  String get statusAccessibilityStillOff =>
      '辅助功能权限仍未开启。请先在系统设置中启用，然后再试一次。如果你刚刚完成授权但系统还没刷新，请退出并重新打开 LockBar。';

  @override
  String get statusLockServiceUnavailable => 'LockBar 无法连接到 macOS 锁屏服务。';

  @override
  String get statusOpenedSystemSettings =>
      '已打开系统设置。请在“隐私与安全性 > 辅助功能”中启用 LockBar。如果启用后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get statusOpenSystemSettingsFailed => 'LockBar 无法自动打开系统设置。';

  @override
  String get statusLaunchAtLoginEnabled => 'LockBar 现在会在你登录时自动启动。';

  @override
  String get statusLaunchAtLoginDisabled => '已关闭“登录时启动”。';

  @override
  String get statusLaunchAtLoginFailed => 'LockBar 无法更新登录启动设置。';

  @override
  String get statusPermissionGrantedClickTrayAgain =>
      '辅助功能权限已开启。再次点击菜单栏图标即可立即锁屏。';

  @override
  String get statusPermissionEnableThenRetry =>
      'LockBar 需要辅助功能权限才能锁屏。请先在系统设置中启用，然后再试一次。如果刚授权后仍未生效，请退出并重新打开 LockBar。';

  @override
  String get statusLockCommandSent => '已发送锁屏指令。';

  @override
  String get statusLockFailureEventSource => 'LockBar 无法创建系统键盘事件源。';

  @override
  String get statusLockFailureEventSequence => 'LockBar 无法构建锁屏快捷键事件序列。';

  @override
  String get statusLockFailureGeneric => 'LockBar 无法触发系统锁屏快捷键。';

  @override
  String get statusLocalePreferenceFailed => 'LockBar 无法保存语言偏好设置。';
}
