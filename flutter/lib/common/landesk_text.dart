import 'package:flutter/widgets.dart';

const _chinese = <String, String>{
  'Private network': '私有网络',
  'Connect with a LAN or Tailscale IP address. Passwords and host approval still apply.':
      '通过局域网或 Tailscale IP 地址连接，仍需密码验证或被控端批准。',
  'Native connections use unencrypted transport. Use Tailscale or a VPN for encrypted transport.':
      '原生直连不加密传输。需要加密时，请搭配 Tailscale 或 VPN 使用。',
  'Direct connection port': '直连端口',
  'HTTPS browser access': 'HTTPS 浏览器访问',
  'HTTPS port': 'HTTPS 端口',
  'Use two different ports between 1 and 65535': '请填写两个不同的端口，范围为 1–65535',
  'Browser access uses the same password and permissions as native connections.':
      '浏览器访问使用与原生连接相同的密码和权限。',
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
