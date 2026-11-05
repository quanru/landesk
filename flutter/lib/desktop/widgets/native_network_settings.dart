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
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    port = TextEditingController(text: _option('direct-access-port', '21118'));
  }

  String translate(String text) => landeskText(context, text);

  String _option(String key, String fallback) {
    final value = bind.mainGetOptionSync(key: key);
    return value.isEmpty ? fallback : value;
  }

  Future<void> save() async {
    final native = int.tryParse(port.text);
    if (native == null || native < 1 || native > 65535) {
      setState(() => error = translate('Use a port between 1 and 65535'));
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await bind.mainSetOption(key: 'direct-access-port', value: '$native');
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    port.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.locked || saving;
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
        FilledButton(onPressed: disabled ? null : () => save(), child: Text(translate('Apply'))),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ],
    ));
  }
}
