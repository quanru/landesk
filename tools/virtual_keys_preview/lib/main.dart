import 'package:flutter/material.dart';
import 'custom_key_overlay.dart';
import 'remote_shortcut.dart';

void main() => runApp(const MaterialApp(home: Preview()));

class Preview extends StatefulWidget {
  const Preview({super.key});
  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final events = <String>[];
  int taps = 0;
  int pans = 0;
  double zoom = 1;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff152033),
        appBar: AppBar(title: const Text('Virtual keys · simulator preview')),
        body: SafeArea(
            child: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => taps++),
            onScaleUpdate: (details) => setState(() {
              pans++;
              zoom = details.scale;
            }),
            child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('UI + event sequence only\nNo remote host connected',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.amber, fontSize: 18)),
              const SizedBox(height: 24),
              Text(
                  'Canvas taps: $taps · moves: $pans · scale: ${zoom.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              Text(events.join('\n'),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 16)),
              const SizedBox(height: 24),
              const Text(
                  'Long press a key to edit. Drag to move.\nTap ✓ to finish. Controller toggles visibility.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
            ])),
          ),
          CustomKeyOverlay(send: (shortcut) async {
            setState(events.clear);
            await sendRemoteShortcut(shortcut, (key, down,
                {required ctrl,
                required alt,
                required shift,
                required command}) async {
              setState(() => events.add('$key ${down ? "DOWN" : "UP"}  '
                  '${ctrl ? "Ctrl " : ""}${alt ? "Alt " : ""}${shift ? "Shift " : ""}${command ? "Cmd" : ""}'));
            });
          }),
        ])),
      );
}
