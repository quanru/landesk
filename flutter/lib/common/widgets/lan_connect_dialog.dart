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
  bool _expanded = false, _busy = false, _passwordVisible = false;
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
              TextFormField(
                key: const ValueKey('lan-endpoint'),
                controller: widget.endpoint,
                enabled: !_busy,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? tr('Invalid IP') : null,
                decoration: const InputDecoration(
                  labelText: 'IP',
                  hintText: '192.168.1.2:21118',
                  prefixIcon: Icon(Icons.desktop_windows_outlined),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _expanded = !_expanded;
                          if (!_expanded) widget.password.clear();
                        }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text('${tr('Username')} · ${tr('Password')}'),
                ),
              ),
              if (_expanded) ...[
                TextFormField(
                  controller: widget.username,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: (value) =>
                      widget.password.text.isNotEmpty &&
                          (value ?? '').trim().isEmpty
                      ? tr('Username missed')
                      : null,
                  decoration: InputDecoration(
                    labelText: tr('Username'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: widget.password,
                  enabled: !_busy,
                  obscureText: !_passwordVisible,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: tr('Password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: tr(
                        _passwordVisible ? 'Hide password' : 'Show password',
                      ),
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _passwordVisible = !_passwordVisible,
                            ),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                CheckboxListTile(
                  key: const ValueKey('lan-remember'),
                  value: _remember,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _remember = value == true),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(tr(_busy ? 'Connecting...' : 'Connect')),
            ],
          ),
        ),
      ],
    );
  }
}
