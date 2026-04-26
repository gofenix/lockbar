import 'ai_models.dart';

enum CommandPanelAction {
  lockNow('lockNow'),
  keepAwake30Minutes('keepAwake30Minutes'),
  keepAwake1Hour('keepAwake1Hour'),
  keepAwake2Hours('keepAwake2Hours'),
  keepAwakeIndefinitely('keepAwakeIndefinitely'),
  cancelKeepAwake('cancelKeepAwake'),
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
    launchAtLoginLabel,
    launchAtLoginEnabled,
    openSettingsLabel,
    quitLabel,
  ].join('|');
}
