part of 'cursor_size_test.dart';

Future<void> _preview(
  WidgetTester tester,
  List<Map<dynamic, dynamic>> registrations,
  String output,
) async {
  tester.view.physicalSize = const Size(820, 360);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final font = FontLoader('Preview');
  await tester.runAsync(() async {
    font.addFont(
      File(
        '/System/Library/Fonts/SFNS.ttf',
      ).readAsBytes().then((v) => ByteData.sublistView(v)),
    );
    await font.load();
  });
  final ffi = _FFI(_Canvas(kRemoteViewStyleAdaptive));
  final bitmap = img.Image(width: 20, height: 30, numChannels: 4);
  for (final pixel in bitmap) {
    if (pixel.x >= 3 &&
        pixel.y >= 2 &&
        pixel.y < 25 &&
        pixel.x <= 3 + (pixel.y - 2) ~/ 2) {
      pixel.setRgba(40, 78, 180, 255);
    }
  }
  final pixels = Uint8List.fromList(img.encodePng(bitmap));
  final cursor = _Cursor(
    CursorData(
      peerId: 'preview',
      id: 'arrow',
      image: bitmap,
      scale: 1,
      data: pixels,
      hotxOrigin: 3,
      hotyOrigin: 2,
      width: 20,
      height: 30,
    ),
    ffi,
  );
  addTearDown(() => _dispose(cursor));
  addTearDown(ffi.canvasModel.dispose);
  final cards = <Widget>[];
  for (final rotation in [
    ViewRotation.none,
    ViewRotation.rot90,
    ViewRotation.rot270,
  ]) {
    buildCursorOfCache(cursor, 1, cursor.cache, rotation: rotation);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final args = registrations.last;
    final data = args['buffer'] as Uint8List;
    final raster = (await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    }))!;
    addTearDown(raster.dispose);
    cards.add(
      Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${rotation.quarterTurns * 90}°',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: RawImage(image: raster, fit: BoxFit.fill,
                      width: (args['width'] as int) * 3,
                      height: (args['height'] as int) * 3,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
                Text(
                  '${args['width']} × ${args['height']}  ·  hotspot ${args['hotX']}, ${args['hotY']}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Preview', colorSchemeSeed: Colors.blue),
      home: RepaintBoundary(
        key: key,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LanDesk · Cursor rotation',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Expanded(child: Row(children: cards)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final shot =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage();
    final data = await shot.toByteData(format: ui.ImageByteFormat.png);
    final file = File(output);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    shot.dispose();
  });
}
