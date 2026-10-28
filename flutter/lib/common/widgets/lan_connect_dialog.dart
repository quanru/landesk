import 'package:flutter/material.dart';

/// A scrollable connection form; controllers remain owned by the connection page.
class LanConnectDialog extends StatefulWidget {
  const LanConnectDialog({
    super.key,
    required this.endpoint,
    required this.username,
    required this.password,
    required this.translate,
    required this.onConnect,
    this.remember = false,
  });
  final TextEditingController endpoint, username, password;
  final String Function(String) translate;
  final Future<bool> Function(bool remember) onConnect;
  final bool remember;

  @override
  State<LanConnectDialog> createState() => _LanConnectDialogState();
}

class _LanConnectDialogState extends State<LanConnectDialog> {
  final _form = GlobalKey<FormState>();
  bool _expanded = false, _busy = false;
  late bool _remember = widget.remember;

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final opened = await widget.onConnect(_remember);
      if (opened && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.translate;
    Widget caption(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
    return AlertDialog(
      scrollable: true,
      title: Text(tr('Connect')),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              caption('IP'),
              TextFormField(
                key: const ValueKey('lan-endpoint'),
                controller: widget.endpoint,
                autocorrect: false,
                enableSuggestions: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? tr('Invalid IP') : null,
                decoration: const InputDecoration(
                  hintText: 'IP / IP:port',
                  prefixIcon: Icon(Icons.desktop_windows_outlined),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _expanded = !_expanded;
                    if (!_expanded) widget.password.clear();
                  }),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text('${tr('Username')} · ${tr('Password')}'),
                ),
              ),
              if (_expanded) ...[
                caption(tr('Username')),
                TextFormField(
                  controller: widget.username,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) =>
                      widget.password.text.isNotEmpty &&
                          (value ?? '').trim().isEmpty
                      ? tr('Username missed')
                      : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 18),
                caption(tr('Password')),
                TextFormField(
                  controller: widget.password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                CheckboxListTile(
                  key: const ValueKey('lan-remember'),
                  value: _remember,
                  onChanged: (value) =>
                      setState(() => _remember = value == true),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(tr('Remember password')),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Cancel')),
        ),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          child: Text(tr('Connect')),
        ),
      ],
    );
  }
}
