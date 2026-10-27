import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/widgets/setting_widgets.dart';
import 'package:flutter_hbb/desktop/pages/desktop_home_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../common/widgets/settings_section_card.dart';

import '../../common.dart';
import '../../consts.dart';
import '../../models/model.dart';
import 'home_page.dart';

class SettingsPage extends StatefulWidget implements PageShape {
  @override
  final title = translate('Settings');

  @override
  final icon = const Icon(Icons.tune_rounded);

  @override
  final appBarActions = const <Widget>[];

  @override
  State<SettingsPage> createState() => _SettingsState();
}

enum KeepScreenOn { never, duringControlled, serviceOn }

KeepScreenOn optionToKeepScreenOn(String value) {
  switch (value) {
    case 'never':
      return KeepScreenOn.never;
    case 'service-on':
      return KeepScreenOn.serviceOn;
    default:
      return KeepScreenOn.duringControlled;
  }
}

class _SettingsState extends State<SettingsPage> {
  var _fingerprint = '';
  var _buildDate = '';
  var _preventSleepWhileConnected = true;
  var _showTerminalExtraKeys = false;

  @override
  void initState() {
    super.initState();
    _preventSleepWhileConnected = mainGetLocalBoolOptionSync(
      kOptionKeepAwakeDuringOutgoingSessions,
    );
    _showTerminalExtraKeys = mainGetLocalBoolOptionSync(
      kOptionEnableShowTerminalExtraKeys,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fingerprint = await bind.mainGetFingerprint();
      final buildDate = await bind.mainGetBuildDate();
      if (!mounted) return;
      setState(() {
        _fingerprint = fingerprint;
        _buildDate = buildDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    Widget entry(
      String title,
      IconData icon,
      VoidCallback action, {
      String? subtitle,
    }) => ListTile(
      leading: Icon(icon, size: 21),
      title: Text(translate(title)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: action,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            SettingsSectionCard(
              title: translate('Connection'),
              children: [
                entry(
                  'Network',
                  Icons.lan_outlined,
                  () => showLanSettingsDialog(context),
                  subtitle:
                      '${translate('Local Address')} · ${translate('Port')}',
                ),
                if (!bind.isIncomingOnly())
                  SwitchListTile(
                    title: Text(
                      translate('keep-awake-during-outgoing-sessions-label'),
                    ),
                    value: _preventSleepWhileConnected,
                    onChanged: (value) async {
                      await mainSetLocalBoolOption(
                        kOptionKeepAwakeDuringOutgoingSessions,
                        value,
                      );
                      if (mounted)
                        setState(() => _preventSleepWhileConnected = value);
                    },
                  ),
              ],
            ),
            if (!bind.isIncomingOnly())
              SettingsSectionCard(
                title: translate('Display'),
                children: [
                  entry(
                    'Display Settings',
                    Icons.desktop_windows_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MobileDisplaySettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            SettingsSectionCard(
              title: translate('Input Control'),
              children: [
                SwitchListTile(
                  title: Text(translate('Show terminal extra keys')),
                  value: _showTerminalExtraKeys,
                  onChanged: (value) async {
                    await mainSetLocalBoolOption(
                      kOptionEnableShowTerminalExtraKeys,
                      value,
                    );
                    if (mounted) setState(() => _showTerminalExtraKeys = value);
                  },
                ),
              ],
            ),
            SettingsSectionCard(
              title: translate('Theme'),
              children: [
                entry(
                  'Theme',
                  Icons.brightness_6_outlined,
                  () => showThemeSettings(gFFI.dialogManager),
                  subtitle: translate(
                    switch (MyTheme.getThemeModePreference()) {
                      ThemeMode.system => 'Follow System',
                      ThemeMode.light => 'Light Theme',
                      ThemeMode.dark => 'Dark Theme',
                    },
                  ),
                ),
                entry(
                  'Language',
                  Icons.translate,
                  () => showLanguageSettings(gFFI.dialogManager),
                ),
              ],
            ),
            SettingsSectionCard(
              title: translate('About'),
              children: [
                ListTile(
                  title: const Text('LanDesk'),
                  subtitle: Text('${translate('Version')}: $version'),
                ),
                ListTile(
                  title: Text(translate('Build Date')),
                  subtitle: Text(_buildDate),
                ),
                ExpansionTile(
                  title: Text(translate('Fingerprint')),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SelectableText(
                        _fingerprint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MobileDisplaySettingsPage extends StatefulWidget {
  const MobileDisplaySettingsPage({super.key});

  @override
  State<MobileDisplaySettingsPage> createState() =>
      _MobileDisplaySettingsPageState();
}

class _MobileDisplaySettingsPageState extends State<MobileDisplaySettingsPage> {
  @override
  Widget build(BuildContext context) {
    final Map codecsJson = jsonDecode(bind.mainSupportedHwdecodings());
    final h264 = codecsJson['h264'] ?? false;
    final h265 = codecsJson['h265'] ?? false;
    final codecList = [
      _RadioEntry('Auto', 'auto'),
      _RadioEntry('VP8', 'vp8'),
      _RadioEntry('VP9', 'vp9'),
      _RadioEntry('AV1', 'av1'),
      if (h264) _RadioEntry('H264', 'h264'),
      if (h265) _RadioEntry('H265', 'h265'),
    ];
    final showCustomImageQuality = false.obs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          translate('Display Settings'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SettingsSectionCard(
                title: translate('Display'),
                children: [
                  _getPopupDialogRadioEntry(
                    title: 'Default View Style',
                    list: [
                      _RadioEntry('Scale original', kRemoteViewStyleOriginal),
                      _RadioEntry('Scale adaptive', kRemoteViewStyleAdaptive),
                    ],
                    getter: () =>
                        bind.mainGetUserDefaultOption(key: kOptionViewStyle),
                    asyncSetter: isOptionFixed(kOptionViewStyle)
                        ? null
                        : (value) => bind.mainSetUserDefaultOption(
                            key: kOptionViewStyle,
                            value: value,
                          ),
                  ),
                  _getPopupDialogRadioEntry(
                    title: 'Default Image Quality',
                    list: [
                      _RadioEntry(
                        'Good image quality',
                        kRemoteImageQualityBest,
                      ),
                      _RadioEntry('Balanced', kRemoteImageQualityBalanced),
                      _RadioEntry(
                        'Optimize reaction time',
                        kRemoteImageQualityLow,
                      ),
                      _RadioEntry('Custom', kRemoteImageQualityCustom),
                    ],
                    getter: () {
                      final value = bind.mainGetUserDefaultOption(
                        key: kOptionImageQuality,
                      );
                      showCustomImageQuality.value =
                          value == kRemoteImageQualityCustom;
                      return value;
                    },
                    asyncSetter: isOptionFixed(kOptionImageQuality)
                        ? null
                        : (value) async {
                            await bind.mainSetUserDefaultOption(
                              key: kOptionImageQuality,
                              value: value,
                            );
                            showCustomImageQuality.value =
                                value == kRemoteImageQualityCustom;
                          },
                    tail: customImageQualitySetting(),
                    showTail: showCustomImageQuality,
                    notCloseValue: kRemoteImageQualityCustom,
                  ),
                  _getPopupDialogRadioEntry(
                    title: 'Default Codec',
                    list: codecList,
                    getter: () => bind.mainGetUserDefaultOption(
                      key: kOptionCodecPreference,
                    ),
                    asyncSetter: isOptionFixed(kOptionCodecPreference)
                        ? null
                        : (value) => bind.mainSetUserDefaultOption(
                            key: kOptionCodecPreference,
                            value: value,
                          ),
                  ),
                ],
              ),
              SettingsSectionCard(
                title: translate('Other Default Options'),
                children: otherDefaultSettings()
                    .map((entry) => _buildBooleanSetting(entry.$1, entry.$2))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooleanSetting(String label, String key) {
    final value = bind.mainGetUserDefaultOption(key: key) == 'Y';
    return SwitchListTile(
      value: value,
      title: Text(translate(label)),
      onChanged: isOptionFixed(key)
          ? null
          : (enabled) async {
              await bind.mainSetUserDefaultOption(
                key: key,
                value: enabled ? 'Y' : defaultOptionNo,
              );
              if (mounted) setState(() {});
            },
    );
  }
}

class _RadioEntry {
  const _RadioEntry(this.label, this.value);

  final String label;
  final String value;
}

typedef _RadioEntryGetter = String Function();
typedef _RadioEntrySetter = Future<void> Function(String);

Widget _getPopupDialogRadioEntry({
  required String title,
  required List<_RadioEntry> list,
  required _RadioEntryGetter getter,
  required _RadioEntrySetter? asyncSetter,
  Widget? tail,
  RxBool? showTail,
  String? notCloseValue,
}) {
  final groupValue = getter().obs;
  final valueText =
      (list
                  .firstWhereOrNull((entry) => entry.value == groupValue.value)
                  ?.label ??
              groupValue.value)
          .obs;

  void refreshValue() {
    groupValue.value = getter();
    valueText.value =
        list
            .firstWhereOrNull((entry) => entry.value == groupValue.value)
            ?.label ??
        groupValue.value;
  }

  void showSelectionDialog() {
    gFFI.dialogManager.show(
      (setState, close, context) => CustomAlertDialog(
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...list.map(
                (entry) => getRadio<String>(
                  Text(translate(entry.label)),
                  entry.value,
                  groupValue.value,
                  asyncSetter == null
                      ? null
                      : (value) async {
                          if (value == null) return;
                          await asyncSetter(value);
                          refreshValue();
                          if (value != notCloseValue) close();
                        },
                ),
              ),
              if (tail != null && showTail != null)
                Obx(() => Offstage(offstage: !showTail.value, child: tail)),
            ],
          ),
        ),
      ),
      backDismiss: true,
      clickMaskDismiss: true,
    );
  }

  return ListTile(
    title: Text(translate(title)),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: asyncSetter == null ? null : showSelectionDialog,
    subtitle: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Obx(
        () => Text(
          translate(valueText.value),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

void showLanguageSettings(OverlayDialogManager dialogManager) async {
  try {
    final languages = json.decode(await bind.mainGetLangs()) as List<dynamic>;
    var language = bind.mainGetLocalOption(key: kCommConfKeyLang);
    dialogManager.show(
      (setState, close, context) {
        void setLanguage(String? value) async {
          if (value == null) return;
          if (language == value) return;
          setState(() => language = value);
          await bind.mainSetLocalOption(key: kCommConfKeyLang, value: value);
          HomePage.homeKey.currentState?.refreshPages();
          Future.delayed(const Duration(milliseconds: 200), close);
        }

        final onChanged = isOptionFixed(kCommConfKeyLang) ? null : setLanguage;
        return CustomAlertDialog(
          content: Column(
            children: [
              getRadio<String>(
                Text(translate('Default')),
                defaultOptionLang,
                language,
                onChanged,
              ),
              Divider(color: MyTheme.border),
              ...languages.map((entry) {
                final key = entry[0] as String;
                final name = entry[1] as String;
                return getRadio<String>(
                  Text(translate(name)),
                  key,
                  language,
                  onChanged,
                );
              }),
            ],
          ),
        );
      },
      backDismiss: true,
      clickMaskDismiss: true,
    );
  } catch (_) {}
}

void showThemeSettings(OverlayDialogManager dialogManager) async {
  var themeMode = MyTheme.getThemeModePreference();
  dialogManager.show(
    (setState, close, context) {
      void setTheme(ThemeMode? value) {
        if (value == null) return;
        if (themeMode == value) return;
        setState(() => themeMode = value);
        MyTheme.changeDarkMode(themeMode);
        Future.delayed(const Duration(milliseconds: 200), close);
      }

      final onChanged = isOptionFixed(kCommConfKeyTheme) ? null : setTheme;
      return CustomAlertDialog(
        content: Column(
          children: [
            getRadio<ThemeMode>(
              Text(translate('Light')),
              ThemeMode.light,
              themeMode,
              onChanged,
            ),
            getRadio<ThemeMode>(
              Text(translate('Dark')),
              ThemeMode.dark,
              themeMode,
              onChanged,
            ),
            getRadio<ThemeMode>(
              Text(translate('Follow System')),
              ThemeMode.system,
              themeMode,
              onChanged,
            ),
          ],
        ),
      );
    },
    backDismiss: true,
    clickMaskDismiss: true,
  );
}
