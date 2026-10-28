import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Available on both desktop and mobile, including builds without an account.
class SourceLicenseSection extends StatelessWidget {
  const SourceLicenseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    const source = 'https://github.com/quanru/landesk';
    const releases = '$source/blob/localdesk/main/docs/licensing/releases.md';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          zh ? '开源许可与源代码' : 'License and source code',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          zh
              ? 'LanDesk 基于 RustDesk 和 SubnetDesk 修改，由 quanru 独立维护，按 AGPL-3.0 提供。原作者及各依赖的版权声明继续有效。本软件不提供担保。'
              : 'LanDesk is modified from RustDesk and SubnetDesk, independently maintained by quanru under AGPL-3.0. Upstream and dependency copyright notices remain applicable. This software comes without warranty.',
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.code),
              label: Text(zh ? '免费获取对应源码' : 'Get corresponding source'),
              onPressed: () async {
                if (!await launchUrl(Uri.parse(releases)) && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: SelectableText(releases)),
                  );
                }
              },
            ),
            TextButton(
              child: const Text('AGPL-3.0'),
              onPressed: () async {
                final text = await rootBundle.loadString('assets/AGPL-3.0.txt');
                if (!context.mounted) return;
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('GNU AGPL v3'),
                    content: SizedBox(
                      width: 640,
                      child: SingleChildScrollView(child: SelectableText(text)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'LanDesk'),
              child: Text(zh ? 'Flutter 依赖许可' : 'Flutter dependency licenses'),
            ),
          ],
        ),
      ],
    );
  }
}
