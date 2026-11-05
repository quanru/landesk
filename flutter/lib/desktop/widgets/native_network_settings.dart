import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../common/landesk_text.dart';
import '../../models/platform_model.dart';

class NativeNetworkSettings extends StatefulWidget {
  const NativeNetworkSettings({super.key, required this.locked});
  final bool locked;
  @override
  State<NativeNetworkSettings> createState() => _NativeNetworkSettingsState();
}

class _NativeNetworkSettingsState extends State<NativeNetworkSettings> {
  late final TextEditingController port;
  late final TextEditingController webPort;
  Timer? poll;
  Map<String, dynamic> status = {};
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    port = TextEditingController(text: _option('direct-access-port', '21118'));
    webPort = TextEditingController(text: _option('web-listen-port', '18123'));
    poll = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
    refresh();
  }

  String translate(String text) => landeskText(context, text);

  String _option(String key, String fallback) {
    final value = bind.mainGetOptionSync(key: key);
    return value.isEmpty ? fallback : value;
  }

  void refresh() {
    try {
      final value = jsonDecode(bind.mainGetOptionSync(key: 'landesk-web-status'));
      if (mounted && value is Map<String, dynamic>) setState(() => status = value);
    } catch (_) {
      // The service may not have written its first status yet.
    }
  }

  Future<void> save({bool? enabled}) async {
    final native = int.tryParse(port.text);
    final web = int.tryParse(webPort.text);
    if (native == null || web == null || native < 1 || native > 65535 ||
        web < 1 || web > 65535 || native == web) {
      setState(() => error = translate('Use two different ports between 1 and 65535'));
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await bind.mainSetOption(key: 'direct-access-port', value: '$native');
      await bind.mainSetOption(key: 'web-listen-port', value: '$web');
      if (enabled != null) {
        await bind.mainSetOption(key: 'web-access-enabled', value: enabled ? 'Y' : 'N');
      }
      refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    poll?.cancel();
    port.dispose();
    webPort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.locked || saving;
    final enabled = bind.mainGetOptionSync(key: 'web-access-enabled') == 'Y';
    return Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(translate('Private network'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(translate('Connect with a LAN or Tailscale IP address. Passwords and host approval still apply.')),
        const SizedBox(height: 8),
        Text(translate('Native connections use unencrypted transport. Use Tailscale or a VPN for encrypted transport.')),
        const SizedBox(height: 16),
        SelectableText(bind.mainGetOptionSync(key: 'landesk-local-endpoints')),
        const SizedBox(height: 16),
        TextField(controller: port, enabled: !disabled, keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: translate('Direct connection port'))),
        const SizedBox(height: 16),
        SwitchListTile(contentPadding: EdgeInsets.zero,
          title: Text(translate('HTTPS browser access')), value: enabled,
          onChanged: disabled ? null : (value) => save(enabled: value)),
        TextField(controller: webPort, enabled: !disabled, keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: translate('HTTPS port'))),
        const SizedBox(height: 12),
        FilledButton(onPressed: disabled ? null : () => save(), child: Text(translate('Apply'))),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (enabled) ...[
          const SizedBox(height: 16),
          Text(translate(status['state']?.toString() ?? 'Starting')),
          for (final endpoint in (status['endpoints'] as List? ?? []))
            SelectableText(endpoint.toString()),
          if (status['last_error']?.toString().isNotEmpty == true)
            Text(status['last_error'].toString()),
          const SizedBox(height: 8),
          Text(translate('Browser access uses the same password and permissions as native connections.')),
        ],
      ],
    ));
  }
}
