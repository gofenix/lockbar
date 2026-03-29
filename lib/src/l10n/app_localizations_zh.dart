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
  String get settingsSubtitle => '菜单栏控制项、权限和智能建议都在这里。';

  @override
  String get heroTitle => '一键锁屏，立即生效。';

  @override
  String get heroDescription => '左键点击菜单栏图标即可立即锁屏，右键点击可打开菜单并管理启动行为。';

  @override
  String get leftClickLocks => '左键立即锁屏';

  @override
  String get rightClickOpensMenu => '右键打开菜单';

  @override
  String get lockingSectionTitle => '锁屏';

  @override
  String get primaryActionTitle => '主点击动作';

  @override
  String get primaryActionDescription => '左键立即锁屏，次键打开命令菜单。';

  @override
  String get primaryActionTipTitle => '首次提示';

  @override
  String get primaryActionTipDescription => '左键立即锁屏，次键打开命令菜单。';

  @override
  String get gotItAction => '知道了';

  @override
  String get manualActionsTitle => '手动动作';

  @override
  String durationMinutesLabel(Object count) {
    return '$count 分钟';
  }

  @override
  String durationSecondsLabel(Object count) {
    return '$count 秒';
  }

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

  @override
  String get statusAiModeEnabled => '智能建议已开启。';

  @override
  String get statusAiModeDisabled => '智能建议已关闭。LockBar 不会采集上下文，也不会联系 AI 服务。';

  @override
  String get statusAiSettingsSaveFailed => 'LockBar 无法保存 AI 设置。';

  @override
  String get statusAiConfigurationSaved => 'AI 连接已保存在本地。';

  @override
  String get statusAiConfigurationMissing =>
      'AI 已开启，但缺少 base URL 或 API key。请先打开设置并保存 AI 连接。';

  @override
  String get statusAiConnectionVerificationRequired =>
      '请先配置、测试并保存 AI 连接，然后再开启智能建议。';

  @override
  String get statusAiConnectionTestSucceeded => 'AI 连接已验证。';

  @override
  String get statusAiConnectionTestFailed =>
      'LockBar 无法验证 AI 连接。请检查 base URL、API key 和接口响应后再试。';

  @override
  String get statusAiRequestTimedOut => 'AI 请求超时了。请稍后重试，或检查网络和接口响应速度。';

  @override
  String get statusAiRequestFailed =>
      'LockBar 无法连接 AI 服务。请检查 API key、网络，或 MiniMax 的 Anthropic 兼容接口地址。';

  @override
  String get statusAiInvalidResponse => 'AI 服务返回了 LockBar 无法解析的响应。';

  @override
  String get statusAiMemoryReset => 'LockBar 已清空当前记忆摘要和动作历史。';

  @override
  String get statusAiMemoryResetFailed => 'LockBar 无法重置 AI 记忆。';

  @override
  String get statusFocusSessionStarted => '专注 session 已开始。';

  @override
  String get statusFocusSessionCancelled => '专注 session 已取消。';

  @override
  String get statusDelayedLockScheduled => '延时锁屏已排队。';

  @override
  String get statusDelayedLockCancelled => '延时锁屏已取消。';

  @override
  String get statusWorkdayReviewStarted => '下班收尾已触发。';

  @override
  String get aiStatusOn => 'AI 已开';

  @override
  String get aiStatusOff => 'AI 已关';

  @override
  String get aiCardTitle => '智能建议';

  @override
  String get aiCardSubtitle => '只有在你开启后才会生效';

  @override
  String get aiLaterAction => '稍后';

  @override
  String get aiNotNowAction => '先不用';

  @override
  String get aiReviewSuggestionAction => '查看建议…';

  @override
  String get aiWhyAction => '为什么现在提醒我？';

  @override
  String get aiWhyInlineTitle => '使用到的信号';

  @override
  String get aiWhyDialogTitle => '这次提醒的依据';

  @override
  String get doneAction => '完成';

  @override
  String aiConfidenceLabel(Object value) {
    return '置信度 $value%';
  }

  @override
  String get aiSectionTitle => 'AI';

  @override
  String get aiSectionDescription =>
      'Memory Coach 不会改掉左键一键锁屏，它只想学习什么时刻的锁屏建议对你真的有帮助。默认只从 LockBar 动作历史和离席返回时机开始。';

  @override
  String get aiConnectionTitle => '连接';

  @override
  String aiConnectionConfiguredDescription(Object baseUrl, Object maskedKey) {
    return 'Base URL：$baseUrl\nAPI key：$maskedKey';
  }

  @override
  String get aiConnectionMissingDescription =>
      '当前还没有已保存的 AI 连接。请先打开“配置…”，测试草稿后再保存。';

  @override
  String aiConnectionStatusLine(Object status) {
    return '状态：$status';
  }

  @override
  String aiConnectionVerifiedAtLine(Object value) {
    return '验证时间：$value';
  }

  @override
  String aiConnectionModelLine(Object value) {
    return '模型：$value';
  }

  @override
  String aiConnectionLastErrorLine(Object value) {
    return '最近错误：$value';
  }

  @override
  String get aiConnectionPendingDraftHint => '检测到了本地未完成配置。请重新打开“配置…”，测试后再保存。';

  @override
  String get aiConnectionNeedsTestHint => '只保存还不够。请先对当前连接执行一次测试，然后再开启智能建议。';

  @override
  String get aiConfigureAction => '配置…';

  @override
  String get aiClearConnectionAction => '清除';

  @override
  String get aiTestConnectionAction => '测试';

  @override
  String get aiTestingConnectionAction => '测试中…';

  @override
  String get aiSuggestionsToggle => 'AI suggestions';

  @override
  String get aiSuggestionsEnabledDescription =>
      'LockBar 只会使用你明确开启的输入，判断这一刻值不值得给你一个锁屏建议。';

  @override
  String get aiSuggestionsDisabledDescription =>
      '只有当你想让 LockBar 学习你的锁屏时机时再开启。开启前不会采集任何内容。';

  @override
  String get aiEnableAction => '开启智能建议';

  @override
  String get aiOnboardingTitle => '开启智能建议';

  @override
  String get aiOnboardingDescription =>
      'LockBar 可以在专注结束、收尾时刻和短暂离席后给出更合适的锁屏建议，但不会改掉左键一键锁屏。';

  @override
  String get aiOnboardingDefaultsTitle => '默认启用的输入';

  @override
  String get aiOnboardingPrivacyFootnote => '其他输入默认都保持关闭，只有你手动开启后才会使用。';

  @override
  String get aiConfigDialogTitle => '配置 AI 连接';

  @override
  String get aiConfigDialogDescription =>
      'LockBar 会把 base URL 和 API key 一起保存在这台 Mac 上的应用本地配置中。';

  @override
  String get aiConfigBaseUrlLabel => 'Base URL';

  @override
  String get aiConfigApiKeyLabel => 'API key';

  @override
  String aiConfigModelLine(Object value) {
    return '模型：$value';
  }

  @override
  String get aiConfigDraftStatusTitle => '草稿测试状态';

  @override
  String aiConfigDraftStatusLine(Object value) {
    return '状态：$value';
  }

  @override
  String get aiConfigDraftNeedsTestHint => '请先测试当前草稿，再执行保存。';

  @override
  String get aiSaveConnectionAction => '保存';

  @override
  String get aiBaseUrlRequired => '请输入 base URL。';

  @override
  String get aiApiKeyRequired => '请输入 API key。';

  @override
  String get aiSavedConnectionStateMissing => '没有已保存连接';

  @override
  String get aiSavedConnectionStateVerifiedHealthy => '已验证且健康';

  @override
  String get aiSavedConnectionStateVerifiedDegraded => '已验证，但最近一次请求失败';

  @override
  String get aiDraftTestStateIdle => '尚未测试';

  @override
  String get aiDraftTestStateTesting => '正在测试草稿';

  @override
  String get aiDraftTestStateSuccess => '草稿已验证';

  @override
  String get aiDraftTestStateFailure => '草稿测试失败';

  @override
  String get aiNetworkStatusLabel => 'AI 网络状态';

  @override
  String get aiCurrentMemoryLabel => '当前记忆摘要';

  @override
  String get aiDataSourcesTitle => '用于判断建议的输入';

  @override
  String get aiRecentSuggestionTitle => '最近一次建议';

  @override
  String get aiDecisionHistoryTitle => '决策历史';

  @override
  String get aiDecisionHistoryDescription =>
      '每次触发都会在本地保留一条完整 trace，包含采集上下文、发给模型的内容、模型返回，以及最后的决策链。';

  @override
  String get aiDecisionHistoryEmpty => '还没有记录到 AI 决策 trace。';

  @override
  String get aiClearHistoryAction => '清空历史';

  @override
  String get aiInspectorStoredLocally => '仅保存在这台 Mac 本地';

  @override
  String get aiInspectorRawContextNotice => '包含原始上下文文本';

  @override
  String get aiInspectorNoCredentialsNotice => '绝不包含 API 凭证';

  @override
  String get aiTraceCollectedSection => '采集到的内容';

  @override
  String get aiTraceSentSection => '发给 AI 的内容';

  @override
  String get aiTraceReturnedSection => 'AI 返回';

  @override
  String get aiTraceOutcomeSection => '最终结果';

  @override
  String get aiTraceEnabledSourcesLabel => '启用的数据源';

  @override
  String get aiTraceContextSnapshotLabel => 'Context snapshot';

  @override
  String get aiTraceMemorySnapshotLabel => 'Memory profile';

  @override
  String get aiTraceRequestBodyLabel => 'Request body';

  @override
  String get aiTraceRawResponseLabel => '原始响应';

  @override
  String get aiTraceParsedResponseLabel => '解析后的响应';

  @override
  String get aiTraceErrorLabel => '错误';

  @override
  String get aiTraceRecommendationLabel => '建议对象';

  @override
  String get aiTraceTriggerFocusEnded => '专注结束';

  @override
  String get aiTraceTriggerWorkdayEnded => '下班收尾';

  @override
  String get aiTraceTriggerDelayedLockRequested => '请求延时锁屏';

  @override
  String get aiTraceTriggerCalendarBoundary => '日历边界';

  @override
  String get aiTraceTriggerBluetoothChanged => '蓝牙变化';

  @override
  String get aiTraceTriggerAwayReturned => '离席与返回';

  @override
  String get aiTraceTriggerNetworkChanged => '网络变化';

  @override
  String get aiTraceTriggerAppContextChanged => '前台 App 语境变化';

  @override
  String get aiTraceTriggerEveningWindDown => '晚间收尾';

  @override
  String get aiTraceOutcomeSuggested => '已给出建议';

  @override
  String get aiTraceOutcomeNoSuggestion => '未给建议';

  @override
  String get aiTraceOutcomeFutureProtectionOnly => '仅未来防护建议';

  @override
  String get aiTraceOutcomeTimedOut => '请求超时';

  @override
  String get aiTraceOutcomeRequestFailed => '请求失败';

  @override
  String get aiTraceOutcomeInvalidResponse => '响应无效';

  @override
  String get aiTraceOutcomeBlockedByConfig => '被配置阻断';

  @override
  String get aiTraceDecisionLockNow => '立即锁屏';

  @override
  String get aiTraceDecisionLaterTwoMinutes => '稍后（2 分钟）';

  @override
  String get aiTraceDecisionLaterFiveMinutes => '稍后（5 分钟）';

  @override
  String get aiTraceDecisionNotNow => '先不用';

  @override
  String get aiTraceDecisionDismissed => '已收起';

  @override
  String get aiTraceDecisionIgnored => '已忽略';

  @override
  String aiRecentSuggestionLabel(Object headline) {
    return '最近一次建议：$headline';
  }

  @override
  String get aiTraySuggestionPrefix => 'AI 提醒';

  @override
  String get aiStartFocusAction => '开始专注';

  @override
  String get aiFocusPreset25 => '专注 25 分钟';

  @override
  String get aiFocusPreset50 => '专注 50 分钟';

  @override
  String get aiCancelFocusAction => '取消专注';

  @override
  String get aiEndWorkdayAction => '结束今天工作';

  @override
  String get aiLockInAction => '延时锁屏…';

  @override
  String get aiLockIn30Seconds => '30 秒后锁屏';

  @override
  String get aiLockIn2Minutes => '2 分钟后锁屏';

  @override
  String get aiLockIn5Minutes => '5 分钟后锁屏';

  @override
  String get aiCancelDelayedLockAction => '取消延时锁屏';

  @override
  String get aiHeadlineFocusEnded => '这一段专注结束了。';

  @override
  String get aiReasonFocusEndedFresh => '你刚完成一段专注。如果现在准备离开，这就是最干净的锁屏时机。';

  @override
  String get aiReasonFocusEndedBuffer =>
      '你平时常会在深度工作后留一个小缓冲。现在可以直接锁，也可以再给自己一点收尾时间。';

  @override
  String get aiHeadlineWorkdayEnded => '今天看起来可以收尾了。';

  @override
  String get aiReasonWorkdayEndedFresh =>
      '你刚刚主动点了结束今天工作。LockBar 可以把这个动作变成一个更干净的收尾。';

  @override
  String get aiReasonWorkdayEndedBuffer =>
      '你通常会在结束工作后再留一点缓冲时间。现在就锁，或者再给自己几分钟都顺。';

  @override
  String get aiHeadlineCalendarBoundary => '检测到会议边界。';

  @override
  String aiReasonCalendarBoundary(Object title) {
    return '“$title” 正好处在你当前上下文的边缘。如果你准备离开，这会是一个不错的锁屏点。';
  }

  @override
  String get aiFallbackCalendarTitle => '这个日程';

  @override
  String get aiHeadlineBluetoothBoundary => '你的设备状态刚变化。';

  @override
  String aiReasonBluetoothBoundary(Object device) {
    return '$device 刚断开或重新连回。LockBar 会把这当作一个很强的离席信号。';
  }

  @override
  String get aiFallbackBluetoothDevice => '一个熟悉的设备';

  @override
  String get aiHeadlineFutureProtection => '刚刚像是有一次没被保护好的离席。';

  @override
  String get aiReasonAwayReturned =>
      '你在空闲一段时间后回来了。LockBar 会把这次当成记忆样本，而不是事后补一个“现在锁屏”的建议。';

  @override
  String get aiHeadlineDelayRequested => '短缓冲已经排上了。';

  @override
  String get aiReasonDelayRequested =>
      '你刚刚选择了延时锁屏。Memory Coach 会记住你更偏好立即锁，还是更喜欢先留一个短缓冲。';

  @override
  String get aiNetworkStatusReady => '已在本地配置';

  @override
  String get aiNetworkStatusTesting => '正在测试连接';

  @override
  String get aiNetworkStatusOnline => '云端接口可用';

  @override
  String get aiNetworkStatusOffline => '云端接口不可用';

  @override
  String get aiNetworkStatusNotConfigured => '连接尚未配置';

  @override
  String get aiDataSourceActionHistory => 'LockBar 动作历史';

  @override
  String get aiDataSourceActionHistoryDescription =>
      '用于学习你通常会在什么时刻主动通过 LockBar 锁屏。';

  @override
  String get aiDataSourceFrontmostApp => '前台 App';

  @override
  String get aiDataSourceFrontmostAppDescription =>
      '提供一个粗粒度线索，帮助判断你现在大概处在什么工作语境里。';

  @override
  String get aiDataSourceWindowTitle => '窗口标题';

  @override
  String get aiDataSourceWindowTitleDescription => '提供更细的应用语境。这是最敏感的一类输入。';

  @override
  String get aiDataSourceCalendar => '日程标题与时间';

  @override
  String get aiDataSourceCalendarDescription => '利用附近日程的时间边界，识别更明确的开始和结束时刻。';

  @override
  String get aiDataSourceIdleState => '离席与返回';

  @override
  String get aiDataSourceIdleStateDescription => '只用于判断你是否离开过这台 Mac，并在之后又回来了。';

  @override
  String get aiDataSourceBluetooth => '蓝牙设备变化';

  @override
  String get aiDataSourceBluetoothDescription => '把熟悉设备的断开或重连，当作一种较弱的离席线索。';

  @override
  String get aiDataSourceNetwork => 'Wi‑Fi / 网络变化';

  @override
  String get aiDataSourceNetworkDescription => '把网络变化当作环境切换线索。';

  @override
  String aiDataSourceStatusLine(Object status) {
    return '当前状态：$status';
  }

  @override
  String get dataSourceStatusOff => '关闭';

  @override
  String get dataSourceStatusOn => '开启';

  @override
  String get dataSourceStatusNeedsPermission => '需要权限';

  @override
  String get dataSourceStatusUnavailable => '不可用';

  @override
  String get privacySectionTitle => '隐私';

  @override
  String get calendarAccessDialogTitle => '开启日程建议';

  @override
  String get calendarAccessDialogBody => '只有在你打开这个来源后，LockBar 才会读取附近的日程标题和时间。';

  @override
  String get windowTitleAccessDialogTitle => '需要辅助功能权限';

  @override
  String get windowTitleAccessDialogBody =>
      '窗口标题使用和一键锁屏相同的 macOS 辅助功能权限。想开启这个来源，请先授予权限。';

  @override
  String get continueAction => '继续';

  @override
  String get cancelAction => '取消';

  @override
  String get aiSignalTimeOfDay => '时间段';

  @override
  String get aiSignalActionHistory => '最近的 LockBar 动作';

  @override
  String get aiSignalFrontmostApp => '前台 App';

  @override
  String get aiSignalWindowTitle => '窗口标题';

  @override
  String get aiSignalCalendar => '日程时间';

  @override
  String get aiSignalIdleState => '离席 / 返回状态';

  @override
  String get aiSignalBluetooth => '蓝牙设备变化';

  @override
  String get aiSignalNetwork => '网络环境';

  @override
  String get aiRitualsTitle => '手动仪式动作';

  @override
  String aiFocusRunningLabel(Object minutes) {
    return '专注 session 进行中：$minutes 分钟';
  }

  @override
  String get aiFocusIdleLabel => '当前没有正在进行的专注 session。';

  @override
  String aiDelayedLockRunningLabel(Object duration) {
    return '延时锁屏已排队：$duration';
  }

  @override
  String get aiDelayedLockIdleLabel => '当前没有排队中的延时锁屏。';

  @override
  String get aiMemoryTitle => 'Memory';

  @override
  String get aiResetMemoryAction => '重置记忆';

  @override
  String get aiMemorySummaryEmpty => '当前还是一份全新的记忆。LockBar 还在学习你的节奏。';

  @override
  String get aiMemoryHabitFocusBuffer => '你通常会在专注结束后给自己留一个短缓冲。';

  @override
  String get aiMemoryHabitWorkdayRunway => '你更喜欢在结束工作后留一点 runway，再做最后锁屏。';

  @override
  String get aiMemoryHabitEarlierPrompts => '你对更早的提醒反应更好，不太吃事后补提醒。';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get preparingLockBar => '正在准备 LockBar…';

  @override
  String get settingsSubtitle => '菜单栏控制项、权限和智能建议都在这里。';

  @override
  String get heroTitle => '一键锁屏，立即生效。';

  @override
  String get heroDescription => '左键点击菜单栏图标即可立即锁屏，右键点击可打开菜单并管理启动行为。';

  @override
  String get leftClickLocks => '左键立即锁屏';

  @override
  String get rightClickOpensMenu => '右键打开菜单';

  @override
  String get lockingSectionTitle => '锁屏';

  @override
  String get primaryActionTitle => '主点击动作';

  @override
  String get primaryActionDescription => '左键立即锁屏，次键打开命令菜单。';

  @override
  String get primaryActionTipTitle => '首次提示';

  @override
  String get primaryActionTipDescription => '左键立即锁屏，次键打开命令菜单。';

  @override
  String get gotItAction => '知道了';

  @override
  String get manualActionsTitle => '手动动作';

  @override
  String durationMinutesLabel(Object count) {
    return '$count 分钟';
  }

  @override
  String durationSecondsLabel(Object count) {
    return '$count 秒';
  }

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

  @override
  String get statusAiModeEnabled => '智能建议已开启。';

  @override
  String get statusAiModeDisabled => '智能建议已关闭。LockBar 不会采集上下文，也不会联系 AI 服务。';

  @override
  String get statusAiSettingsSaveFailed => 'LockBar 无法保存 AI 设置。';

  @override
  String get statusAiConfigurationSaved => 'AI 连接已保存在本地。';

  @override
  String get statusAiConfigurationMissing =>
      'AI 已开启，但缺少 base URL 或 API key。请先打开设置并保存 AI 连接。';

  @override
  String get statusAiConnectionVerificationRequired =>
      '请先配置、测试并保存 AI 连接，然后再开启智能建议。';

  @override
  String get statusAiConnectionTestSucceeded => 'AI 连接已验证。';

  @override
  String get statusAiConnectionTestFailed =>
      'LockBar 无法验证 AI 连接。请检查 base URL、API key 和接口响应后再试。';

  @override
  String get statusAiRequestTimedOut => 'AI 请求超时了。请稍后重试，或检查网络和接口响应速度。';

  @override
  String get statusAiRequestFailed =>
      'LockBar 无法连接 AI 服务。请检查 API key、网络，或 MiniMax 的 Anthropic 兼容接口地址。';

  @override
  String get statusAiInvalidResponse => 'AI 服务返回了 LockBar 无法解析的响应。';

  @override
  String get statusAiMemoryReset => 'LockBar 已清空当前记忆摘要和动作历史。';

  @override
  String get statusAiMemoryResetFailed => 'LockBar 无法重置 AI 记忆。';

  @override
  String get statusFocusSessionStarted => '专注 session 已开始。';

  @override
  String get statusFocusSessionCancelled => '专注 session 已取消。';

  @override
  String get statusDelayedLockScheduled => '延时锁屏已排队。';

  @override
  String get statusDelayedLockCancelled => '延时锁屏已取消。';

  @override
  String get statusWorkdayReviewStarted => '下班收尾已触发。';

  @override
  String get aiStatusOn => 'AI 已开';

  @override
  String get aiStatusOff => 'AI 已关';

  @override
  String get aiCardTitle => '智能建议';

  @override
  String get aiCardSubtitle => '只有在你开启后才会生效';

  @override
  String get aiLaterAction => '稍后';

  @override
  String get aiNotNowAction => '先不用';

  @override
  String get aiReviewSuggestionAction => '查看建议…';

  @override
  String get aiWhyAction => '为什么现在提醒我？';

  @override
  String get aiWhyInlineTitle => '使用到的信号';

  @override
  String get aiWhyDialogTitle => '这次提醒的依据';

  @override
  String get doneAction => '完成';

  @override
  String aiConfidenceLabel(Object value) {
    return '置信度 $value%';
  }

  @override
  String get aiSectionTitle => 'AI';

  @override
  String get aiSectionDescription =>
      'Memory Coach 不会改掉左键一键锁屏，它只想学习什么时刻的锁屏建议对你真的有帮助。默认只从 LockBar 动作历史和离席返回时机开始。';

  @override
  String get aiConnectionTitle => '连接';

  @override
  String aiConnectionConfiguredDescription(Object baseUrl, Object maskedKey) {
    return 'Base URL：$baseUrl\nAPI key：$maskedKey';
  }

  @override
  String get aiConnectionMissingDescription =>
      '当前还没有已保存的 AI 连接。请先打开“配置…”，测试草稿后再保存。';

  @override
  String aiConnectionStatusLine(Object status) {
    return '状态：$status';
  }

  @override
  String aiConnectionVerifiedAtLine(Object value) {
    return '验证时间：$value';
  }

  @override
  String aiConnectionModelLine(Object value) {
    return '模型：$value';
  }

  @override
  String aiConnectionLastErrorLine(Object value) {
    return '最近错误：$value';
  }

  @override
  String get aiConnectionPendingDraftHint => '检测到了本地未完成配置。请重新打开“配置…”，测试后再保存。';

  @override
  String get aiConnectionNeedsTestHint => '只保存还不够。请先对当前连接执行一次测试，然后再开启智能建议。';

  @override
  String get aiConfigureAction => '配置…';

  @override
  String get aiClearConnectionAction => '清除';

  @override
  String get aiTestConnectionAction => '测试';

  @override
  String get aiTestingConnectionAction => '测试中…';

  @override
  String get aiSuggestionsToggle => 'AI suggestions';

  @override
  String get aiSuggestionsEnabledDescription =>
      'LockBar 只会使用你明确开启的输入，判断这一刻值不值得给你一个锁屏建议。';

  @override
  String get aiSuggestionsDisabledDescription =>
      '只有当你想让 LockBar 学习你的锁屏时机时再开启。开启前不会采集任何内容。';

  @override
  String get aiEnableAction => '开启智能建议';

  @override
  String get aiOnboardingTitle => '开启智能建议';

  @override
  String get aiOnboardingDescription =>
      'LockBar 可以在专注结束、收尾时刻和短暂离席后给出更合适的锁屏建议，但不会改掉左键一键锁屏。';

  @override
  String get aiOnboardingDefaultsTitle => '默认启用的输入';

  @override
  String get aiOnboardingPrivacyFootnote => '其他输入默认都保持关闭，只有你手动开启后才会使用。';

  @override
  String get aiConfigDialogTitle => '配置 AI 连接';

  @override
  String get aiConfigDialogDescription =>
      'LockBar 会把 base URL 和 API key 一起保存在这台 Mac 上的应用本地配置中。';

  @override
  String get aiConfigBaseUrlLabel => 'Base URL';

  @override
  String get aiConfigApiKeyLabel => 'API key';

  @override
  String aiConfigModelLine(Object value) {
    return '模型：$value';
  }

  @override
  String get aiConfigDraftStatusTitle => '草稿测试状态';

  @override
  String aiConfigDraftStatusLine(Object value) {
    return '状态：$value';
  }

  @override
  String get aiConfigDraftNeedsTestHint => '请先测试当前草稿，再执行保存。';

  @override
  String get aiSaveConnectionAction => '保存';

  @override
  String get aiBaseUrlRequired => '请输入 base URL。';

  @override
  String get aiApiKeyRequired => '请输入 API key。';

  @override
  String get aiSavedConnectionStateMissing => '没有已保存连接';

  @override
  String get aiSavedConnectionStateVerifiedHealthy => '已验证且健康';

  @override
  String get aiSavedConnectionStateVerifiedDegraded => '已验证，但最近一次请求失败';

  @override
  String get aiDraftTestStateIdle => '尚未测试';

  @override
  String get aiDraftTestStateTesting => '正在测试草稿';

  @override
  String get aiDraftTestStateSuccess => '草稿已验证';

  @override
  String get aiDraftTestStateFailure => '草稿测试失败';

  @override
  String get aiNetworkStatusLabel => 'AI 网络状态';

  @override
  String get aiCurrentMemoryLabel => '当前记忆摘要';

  @override
  String get aiDataSourcesTitle => '用于判断建议的输入';

  @override
  String get aiRecentSuggestionTitle => '最近一次建议';

  @override
  String get aiDecisionHistoryTitle => '决策历史';

  @override
  String get aiDecisionHistoryDescription =>
      '每次触发都会在本地保留一条完整 trace，包含采集上下文、发给模型的内容、模型返回，以及最后的决策链。';

  @override
  String get aiDecisionHistoryEmpty => '还没有记录到 AI 决策 trace。';

  @override
  String get aiClearHistoryAction => '清空历史';

  @override
  String get aiInspectorStoredLocally => '仅保存在这台 Mac 本地';

  @override
  String get aiInspectorRawContextNotice => '包含原始上下文文本';

  @override
  String get aiInspectorNoCredentialsNotice => '绝不包含 API 凭证';

  @override
  String get aiTraceCollectedSection => '采集到的内容';

  @override
  String get aiTraceSentSection => '发给 AI 的内容';

  @override
  String get aiTraceReturnedSection => 'AI 返回';

  @override
  String get aiTraceOutcomeSection => '最终结果';

  @override
  String get aiTraceEnabledSourcesLabel => '启用的数据源';

  @override
  String get aiTraceContextSnapshotLabel => 'Context snapshot';

  @override
  String get aiTraceMemorySnapshotLabel => 'Memory profile';

  @override
  String get aiTraceRequestBodyLabel => 'Request body';

  @override
  String get aiTraceRawResponseLabel => '原始响应';

  @override
  String get aiTraceParsedResponseLabel => '解析后的响应';

  @override
  String get aiTraceErrorLabel => '错误';

  @override
  String get aiTraceRecommendationLabel => '建议对象';

  @override
  String get aiTraceTriggerFocusEnded => '专注结束';

  @override
  String get aiTraceTriggerWorkdayEnded => '下班收尾';

  @override
  String get aiTraceTriggerDelayedLockRequested => '请求延时锁屏';

  @override
  String get aiTraceTriggerCalendarBoundary => '日历边界';

  @override
  String get aiTraceTriggerBluetoothChanged => '蓝牙变化';

  @override
  String get aiTraceTriggerAwayReturned => '离席与返回';

  @override
  String get aiTraceTriggerNetworkChanged => '网络变化';

  @override
  String get aiTraceTriggerAppContextChanged => '前台 App 语境变化';

  @override
  String get aiTraceTriggerEveningWindDown => '晚间收尾';

  @override
  String get aiTraceOutcomeSuggested => '已给出建议';

  @override
  String get aiTraceOutcomeNoSuggestion => '未给建议';

  @override
  String get aiTraceOutcomeFutureProtectionOnly => '仅未来防护建议';

  @override
  String get aiTraceOutcomeTimedOut => '请求超时';

  @override
  String get aiTraceOutcomeRequestFailed => '请求失败';

  @override
  String get aiTraceOutcomeInvalidResponse => '响应无效';

  @override
  String get aiTraceOutcomeBlockedByConfig => '被配置阻断';

  @override
  String get aiTraceDecisionLockNow => '立即锁屏';

  @override
  String get aiTraceDecisionLaterTwoMinutes => '稍后（2 分钟）';

  @override
  String get aiTraceDecisionLaterFiveMinutes => '稍后（5 分钟）';

  @override
  String get aiTraceDecisionNotNow => '先不用';

  @override
  String get aiTraceDecisionDismissed => '已收起';

  @override
  String get aiTraceDecisionIgnored => '已忽略';

  @override
  String aiRecentSuggestionLabel(Object headline) {
    return '最近一次建议：$headline';
  }

  @override
  String get aiTraySuggestionPrefix => 'AI 提醒';

  @override
  String get aiStartFocusAction => '开始专注';

  @override
  String get aiFocusPreset25 => '专注 25 分钟';

  @override
  String get aiFocusPreset50 => '专注 50 分钟';

  @override
  String get aiCancelFocusAction => '取消专注';

  @override
  String get aiEndWorkdayAction => '结束今天工作';

  @override
  String get aiLockInAction => '延时锁屏…';

  @override
  String get aiLockIn30Seconds => '30 秒后锁屏';

  @override
  String get aiLockIn2Minutes => '2 分钟后锁屏';

  @override
  String get aiLockIn5Minutes => '5 分钟后锁屏';

  @override
  String get aiCancelDelayedLockAction => '取消延时锁屏';

  @override
  String get aiHeadlineFocusEnded => '这一段专注结束了。';

  @override
  String get aiReasonFocusEndedFresh => '你刚完成一段专注。如果现在准备离开，这就是最干净的锁屏时机。';

  @override
  String get aiReasonFocusEndedBuffer =>
      '你平时常会在深度工作后留一个小缓冲。现在可以直接锁，也可以再给自己一点收尾时间。';

  @override
  String get aiHeadlineWorkdayEnded => '今天看起来可以收尾了。';

  @override
  String get aiReasonWorkdayEndedFresh =>
      '你刚刚主动点了结束今天工作。LockBar 可以把这个动作变成一个更干净的收尾。';

  @override
  String get aiReasonWorkdayEndedBuffer =>
      '你通常会在结束工作后再留一点缓冲时间。现在就锁，或者再给自己几分钟都顺。';

  @override
  String get aiHeadlineCalendarBoundary => '检测到会议边界。';

  @override
  String aiReasonCalendarBoundary(Object title) {
    return '“$title” 正好处在你当前上下文的边缘。如果你准备离开，这会是一个不错的锁屏点。';
  }

  @override
  String get aiFallbackCalendarTitle => '这个日程';

  @override
  String get aiHeadlineBluetoothBoundary => '你的设备状态刚变化。';

  @override
  String aiReasonBluetoothBoundary(Object device) {
    return '$device 刚断开或重新连回。LockBar 会把这当作一个很强的离席信号。';
  }

  @override
  String get aiFallbackBluetoothDevice => '一个熟悉的设备';

  @override
  String get aiHeadlineFutureProtection => '刚刚像是有一次没被保护好的离席。';

  @override
  String get aiReasonAwayReturned =>
      '你在空闲一段时间后回来了。LockBar 会把这次当成记忆样本，而不是事后补一个“现在锁屏”的建议。';

  @override
  String get aiHeadlineDelayRequested => '短缓冲已经排上了。';

  @override
  String get aiReasonDelayRequested =>
      '你刚刚选择了延时锁屏。Memory Coach 会记住你更偏好立即锁，还是更喜欢先留一个短缓冲。';

  @override
  String get aiNetworkStatusReady => '已在本地配置';

  @override
  String get aiNetworkStatusTesting => '正在测试连接';

  @override
  String get aiNetworkStatusOnline => '云端接口可用';

  @override
  String get aiNetworkStatusOffline => '云端接口不可用';

  @override
  String get aiNetworkStatusNotConfigured => '连接尚未配置';

  @override
  String get aiDataSourceActionHistory => 'LockBar 动作历史';

  @override
  String get aiDataSourceActionHistoryDescription =>
      '用于学习你通常会在什么时刻主动通过 LockBar 锁屏。';

  @override
  String get aiDataSourceFrontmostApp => '前台 App';

  @override
  String get aiDataSourceFrontmostAppDescription =>
      '提供一个粗粒度线索，帮助判断你现在大概处在什么工作语境里。';

  @override
  String get aiDataSourceWindowTitle => '窗口标题';

  @override
  String get aiDataSourceWindowTitleDescription => '提供更细的应用语境。这是最敏感的一类输入。';

  @override
  String get aiDataSourceCalendar => '日程标题与时间';

  @override
  String get aiDataSourceCalendarDescription => '利用附近日程的时间边界，识别更明确的开始和结束时刻。';

  @override
  String get aiDataSourceIdleState => '离席与返回';

  @override
  String get aiDataSourceIdleStateDescription => '只用于判断你是否离开过这台 Mac，并在之后又回来了。';

  @override
  String get aiDataSourceBluetooth => '蓝牙设备变化';

  @override
  String get aiDataSourceBluetoothDescription => '把熟悉设备的断开或重连，当作一种较弱的离席线索。';

  @override
  String get aiDataSourceNetwork => 'Wi‑Fi / 网络变化';

  @override
  String get aiDataSourceNetworkDescription => '把网络变化当作环境切换线索。';

  @override
  String aiDataSourceStatusLine(Object status) {
    return '当前状态：$status';
  }

  @override
  String get dataSourceStatusOff => '关闭';

  @override
  String get dataSourceStatusOn => '开启';

  @override
  String get dataSourceStatusNeedsPermission => '需要权限';

  @override
  String get dataSourceStatusUnavailable => '不可用';

  @override
  String get privacySectionTitle => '隐私';

  @override
  String get calendarAccessDialogTitle => '开启日程建议';

  @override
  String get calendarAccessDialogBody => '只有在你打开这个来源后，LockBar 才会读取附近的日程标题和时间。';

  @override
  String get windowTitleAccessDialogTitle => '需要辅助功能权限';

  @override
  String get windowTitleAccessDialogBody =>
      '窗口标题使用和一键锁屏相同的 macOS 辅助功能权限。想开启这个来源，请先授予权限。';

  @override
  String get continueAction => '继续';

  @override
  String get cancelAction => '取消';

  @override
  String get aiSignalTimeOfDay => '时间段';

  @override
  String get aiSignalActionHistory => '最近的 LockBar 动作';

  @override
  String get aiSignalFrontmostApp => '前台 App';

  @override
  String get aiSignalWindowTitle => '窗口标题';

  @override
  String get aiSignalCalendar => '日程时间';

  @override
  String get aiSignalIdleState => '离席 / 返回状态';

  @override
  String get aiSignalBluetooth => '蓝牙设备变化';

  @override
  String get aiSignalNetwork => '网络环境';

  @override
  String get aiRitualsTitle => '手动仪式动作';

  @override
  String aiFocusRunningLabel(Object minutes) {
    return '专注 session 进行中：$minutes 分钟';
  }

  @override
  String get aiFocusIdleLabel => '当前没有正在进行的专注 session。';

  @override
  String aiDelayedLockRunningLabel(Object duration) {
    return '延时锁屏已排队：$duration';
  }

  @override
  String get aiDelayedLockIdleLabel => '当前没有排队中的延时锁屏。';

  @override
  String get aiMemoryTitle => 'Memory';

  @override
  String get aiResetMemoryAction => '重置记忆';

  @override
  String get aiMemorySummaryEmpty => '当前还是一份全新的记忆。LockBar 还在学习你的节奏。';

  @override
  String get aiMemoryHabitFocusBuffer => '你通常会在专注结束后给自己留一个短缓冲。';

  @override
  String get aiMemoryHabitWorkdayRunway => '你更喜欢在结束工作后留一点 runway，再做最后锁屏。';

  @override
  String get aiMemoryHabitEarlierPrompts => '你对更早的提醒反应更好，不太吃事后补提醒。';
}
