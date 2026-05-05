import 'ai_models.dart';

enum CommandPanelAction {
  lockNow('lockNow'),
  keepAwake30Minutes('keepAwake30Minutes'),
  keepAwake1Hour('keepAwake1Hour'),
  keepAwake2Hours('keepAwake2Hours'),
  keepAwakeIndefinitely('keepAwakeIndefinitely'),
  cancelKeepAwake('cancelKeepAwake'),
  setAppearanceLight('setAppearanceLight'),
  setAppearanceDark('setAppearanceDark'),
  setAppearanceAutomatic('setAppearanceAutomatic'),
  toggleLaunchAtLogin('toggleLaunchAtLogin'),
  openSettings('openSettings'),
  quit('quit'),
  hide('hide');

  const CommandPanelAction(this.storageKey);

  final String storageKey;

  static CommandPanelAction fromStorageKey(String? value) {
    for (final action in values) {
      if (action.storageKey == value) {
        return action;
      }
    }
    return CommandPanelAction.hide;
  }
}

enum AppearanceMode {
  light('light'),
  dark('dark'),
  automatic('automatic');

  const AppearanceMode(this.storageKey);

  final String storageKey;

  static AppearanceMode fromStorageKey(String? value) {
    for (final mode in values) {
      if (mode.storageKey == value) {
        return mode;
      }
    }
    return AppearanceMode.light;
  }
}

class BluetoothBatteryDevice {
  const BluetoothBatteryDevice({
    required this.name,
    this.batteryLevel,
    this.leftBatteryLevel,
    this.rightBatteryLevel,
    this.caseBatteryLevel,
  });

  final String name;
  final int? batteryLevel;
  final int? leftBatteryLevel;
  final int? rightBatteryLevel;
  final int? caseBatteryLevel;

  bool get hasBatteryLevel =>
      batteryLevel != null ||
      leftBatteryLevel != null ||
      rightBatteryLevel != null ||
      caseBatteryLevel != null;

  Map<String, Object?> toMap() => {
    'name': name,
    'batteryLevel': batteryLevel,
    'leftBatteryLevel': leftBatteryLevel,
    'rightBatteryLevel': rightBatteryLevel,
    'caseBatteryLevel': caseBatteryLevel,
  };

  String get signature => [
    name,
    batteryLevel ?? 'none',
    leftBatteryLevel ?? 'none',
    rightBatteryLevel ?? 'none',
    caseBatteryLevel ?? 'none',
  ].join(':');

  static BluetoothBatteryDevice? fromMap(Map<dynamic, dynamic> map) {
    final name = (map['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return null;
    }

    return BluetoothBatteryDevice(
      name: name,
      batteryLevel: _parseBatteryLevel(map['batteryLevel']),
      leftBatteryLevel: _parseBatteryLevel(map['leftBatteryLevel']),
      rightBatteryLevel: _parseBatteryLevel(map['rightBatteryLevel']),
      caseBatteryLevel: _parseBatteryLevel(map['caseBatteryLevel']),
    );
  }

  static int compareByName(
    BluetoothBatteryDevice lhs,
    BluetoothBatteryDevice rhs,
  ) {
    final lhsName = lhs.name.toLowerCase();
    final rhsName = rhs.name.toLowerCase();
    final nameOrder = lhsName.compareTo(rhsName);
    return nameOrder == 0 ? lhs.name.compareTo(rhs.name) : nameOrder;
  }

  static int? _parseBatteryLevel(Object? value) {
    final level = switch (value) {
      final int intValue => intValue,
      final num numValue => numValue.round(),
      final String stringValue => int.tryParse(stringValue.trim()),
      _ => null,
    };
    if (level == null || level < 0 || level > 100) {
      return null;
    }
    return level;
  }
}

class CommandPanelData {
  const CommandPanelData({
    required this.title,
    required this.statusText,
    required this.subtitleText,
    required this.lockNowLabel,
    required this.canLockNow,
    required this.keepAwakeTitle,
    required this.keepAwakeSubtitle,
    required this.keepAwakeActive,
    required this.keepAwakePreset,
    required this.keepAwake30MinutesLabel,
    required this.keepAwake1HourLabel,
    required this.keepAwake2HoursLabel,
    required this.keepAwakeIndefinitelyLabel,
    required this.cancelKeepAwakeLabel,
    required this.appearanceTitle,
    required this.appearanceMode,
    required this.appearanceLightLabel,
    required this.appearanceDarkLabel,
    required this.appearanceAutomaticLabel,
    required this.bluetoothDevicesTitle,
    required this.bluetoothDevices,
    required this.launchAtLoginLabel,
    required this.launchAtLoginEnabled,
    required this.openSettingsLabel,
    required this.quitLabel,
  });

  final String title;
  final String statusText;
  final String subtitleText;
  final String lockNowLabel;
  final bool canLockNow;
  final String keepAwakeTitle;
  final String keepAwakeSubtitle;
  final bool keepAwakeActive;
  final KeepAwakePreset? keepAwakePreset;
  final String keepAwake30MinutesLabel;
  final String keepAwake1HourLabel;
  final String keepAwake2HoursLabel;
  final String keepAwakeIndefinitelyLabel;
  final String cancelKeepAwakeLabel;
  final String appearanceTitle;
  final AppearanceMode appearanceMode;
  final String appearanceLightLabel;
  final String appearanceDarkLabel;
  final String appearanceAutomaticLabel;
  final String bluetoothDevicesTitle;
  final List<BluetoothBatteryDevice> bluetoothDevices;
  final String launchAtLoginLabel;
  final bool launchAtLoginEnabled;
  final String openSettingsLabel;
  final String quitLabel;

  Map<String, Object?> toMap() => {
    'title': title,
    'statusText': statusText,
    'subtitleText': subtitleText,
    'lockNowLabel': lockNowLabel,
    'canLockNow': canLockNow,
    'keepAwakeTitle': keepAwakeTitle,
    'keepAwakeSubtitle': keepAwakeSubtitle,
    'keepAwakeActive': keepAwakeActive,
    'keepAwakePreset': keepAwakePreset?.name,
    'keepAwake30MinutesLabel': keepAwake30MinutesLabel,
    'keepAwake1HourLabel': keepAwake1HourLabel,
    'keepAwake2HoursLabel': keepAwake2HoursLabel,
    'keepAwakeIndefinitelyLabel': keepAwakeIndefinitelyLabel,
    'cancelKeepAwakeLabel': cancelKeepAwakeLabel,
    'appearanceTitle': appearanceTitle,
    'appearanceMode': appearanceMode.storageKey,
    'appearanceLightLabel': appearanceLightLabel,
    'appearanceDarkLabel': appearanceDarkLabel,
    'appearanceAutomaticLabel': appearanceAutomaticLabel,
    'bluetoothDevicesTitle': bluetoothDevicesTitle,
    'bluetoothDevices': bluetoothDevices
        .map((device) => device.toMap())
        .toList(growable: false),
    'launchAtLoginLabel': launchAtLoginLabel,
    'launchAtLoginEnabled': launchAtLoginEnabled,
    'openSettingsLabel': openSettingsLabel,
    'quitLabel': quitLabel,
  };

  String get signature => [
    title,
    statusText,
    subtitleText,
    lockNowLabel,
    canLockNow,
    keepAwakeTitle,
    keepAwakeSubtitle,
    keepAwakeActive,
    keepAwakePreset?.name ?? 'none',
    keepAwake30MinutesLabel,
    keepAwake1HourLabel,
    keepAwake2HoursLabel,
    keepAwakeIndefinitelyLabel,
    cancelKeepAwakeLabel,
    appearanceTitle,
    appearanceMode.storageKey,
    appearanceLightLabel,
    appearanceDarkLabel,
    appearanceAutomaticLabel,
    bluetoothDevicesTitle,
    bluetoothDevices.map((device) => device.signature).join(','),
    launchAtLoginLabel,
    launchAtLoginEnabled,
    openSettingsLabel,
    quitLabel,
  ].join('|');
}
