import 'package:flutter/widgets.dart';

const _chinese = <String, String>{
  'Settings protected during remote access': '远控连接期间，设置已受保护',
  'Disconnect the remote session, then unlock Security settings on this computer to change the password. Settings become available automatically after disconnection.': '当前有远控连接，且未允许远端修改配置。请先断开连接，再在这台电脑上解锁安全设置、更改密码。连接断开后，设置会自动恢复操作。',
  'Back to home': '返回首页',
  'Private network': '私有网络',
  'Connect with a LAN or Tailscale IP address. Passwords and host approval still apply.':
      '通过局域网或 Tailscale IP 地址连接，仍需密码验证或被控端批准。',
  'Native connections use unencrypted transport. Use Tailscale or a VPN for encrypted transport.':
      '原生直连不加密传输。需要加密时，请搭配 Tailscale 或 VPN 使用。',
  'Direct connection port': '直连端口',
  'Use a port between 1 and 65535': '请填写 1–65535 之间的端口',
  'Apply': '应用',
  'Starting': '正在启动',
  'starting': '正在启动',
  'listening': '已就绪',
  'disabled': '未开启',
  'error': '启动失败',
  'Virtual keys': '虚拟按键',
  'Edit layout': '编辑布局',
  'All windows': '窗口概览',
};

String landeskText(BuildContext context, String text) {
  final locale = Localizations.maybeLocaleOf(context);
  if (locale?.languageCode == 'zh') return _chinese[text] ?? text;
  return text;
}
