import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/generated_bridge.dart' show CursorShape;
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/native/custom_cursor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

part 'cursor_replay_helpers.dart';
part 'cursor_recovery_cases.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final channel = Platform.isWindows
      ? SystemChannels.mouseCursor
      : const MethodChannel('flutter_custom_cursor');
  setUp(() {
    registered.clear();
    deleted.clear();
    _captureCursorCalls(binding, channel, registered, deleted);
    ffi = _FFI();
  });
  tearDown(() {
    ffi.cursorModel.disposeImages();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'only the shape in use keeps an image, and a shape its native cursor holds '
    'keeps no pixels',
    () async {
      final cursor = ffi.cursorModel;
      for (var round = 0; round < 3; round++) {
        for (final (id, seed) in [('1', 1), ('2', 2), ('3', 3)]) {
          await _feed(ffi, id, seed: seed);
          buildCursorOfCache(cursor, 1.0, cursor.cache);
          await _settle();
        }
      }
      expect(ffi.cursorModel.shapeIds, ['3']);
      for (final id in ['1', '2']) {
        expect(ffi.cursorModel.cachedShape(id)!.hasPixels, isFalse);
        expect(ffi.cursorModel.cachedShape(id)!.data, isNull);
      }
      expect(ffi.cursor.fetched, isEmpty);
    },
  );

  test(
    'the shape in use keeps its pixels, and a new raster is made at once',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, '1', size: 32);
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      expect(cursor.cache!.hasPixels, isTrue);
      expect(
        buildCursorOfCache(cursor, 0.5, cursor.cache),
        isNot(MouseCursor.defer),
      );
      await _settle();
      expect(ffi.cursor.fetched, isEmpty, reason: 'nothing had to be decoded');
      expect(registered.length, 2);
      expect((cursor.cache!.rasterWidth, cursor.cache!.rasterHeight), (16, 16));

      await _feed(ffi, '2');
      expect(
        cursor.cachedShape('1')!.hasPixels,
        isFalse,
        reason: 'switched away from, a shape keeps no pixels',
      );
      _select(ffi, '1');
      expect(
        buildCursorOfCache(cursor, 0.5, cursor.cache),
        isNot(MouseCursor.defer),
      );
      await _settle();
      expect(registered.length, 2, reason: 'its native cursor is still there');
      expect(ffi.cursor.fetched, isEmpty);
    },
  );

  test(
    'native cursors stay for the session, every raster of every shape',
    () async {
      // A delete frees nothing on Windows, so none is deleted before the session ends.
      final cursor = ffi.cursorModel;
      for (var i = 0; i < 100; i++) {
        await _feed(ffi, '$i', size: 32);
        buildCursorOfCache(cursor, 1.0, cursor.cache);
        await _settle();
      }
      expect(deleted, isEmpty);
      expect(cursor.cachedKeys.length, 100);

      _select(ffi, '0');
      expect(
        _key(buildCursorOfCache(cursor, 1.0, cursor.cache)),
        cursor.nativeKey(cursor.cache!, 1.0),
      );
      await _settle();
      expect(ffi.cursor.fetched, isEmpty, reason: 'its cursor is still there');
      expect(registered.length, 100);
    },
  );

  test(
    'a raster made before is found again after the shape was switched away from',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, 'A', size: 32);
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      final first = registered.single;
      buildCursorOfCache(cursor, 0.5, cursor.cache);
      await _settle();
      await _feed(ffi, 'B');
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      final count = registered.length;

      _select(ffi, 'A'); // its pixels went; its cursors at both rasters stay
      expect(_key(buildCursorOfCache(cursor, 1.0, cursor.cache)), first);
      await _settle();
      expect(ffi.cursor.fetched, isEmpty);
      expect(registered.length, count);
    },
  );

  test(
    'a new raster of a shape without pixels keeps the cursor shown before',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, '1', size: 32);
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      await _feed(ffi, '2', size: 32);
      final shown = _key(buildCursorOfCache(cursor, 1.0, cursor.cache));
      await _settle();
      _select(ffi, '1'); // its native cursor held its pixels, so they went
      expect(_key(buildCursorOfCache(cursor, 0.5, cursor.cache)), shown);
      await _settle();
      expect(ffi.cursor.fetched, ['1']);
      expect(
        _key(buildCursorOfCache(cursor, 0.5, cursor.cache)),
        cursor.nativeKey(cursor.cache!, 0.5),
      );
    },
  );

  test(
    'shapes that keep decoding late still get their native cursors',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, 'arrow');
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      // A and B arrive, each decoding only after the peer moved on.
      for (final (id, seed) in [('A', 1), ('B', 2)]) {
        final pixels = _pixels(8, seed);
        ffi.cursor.core[id] = CursorShape(
          hotx: 0,
          hoty: 0,
          width: 8,
          height: 8,
          colors: pixels,
        );
        final decoding = ffi.ffiModel.handleCursorData(id, 0, 0, 8, 8, pixels);
        _select(ffi, 'arrow');
        await decoding;
      }
      // Each fetch answers only after the next switch.
      ffi.cursor.holdFetches = true;
      for (var i = 0; i < 6; i++) {
        _select(ffi, i.isEven ? 'A' : 'B');
        ffi.cursor.answerFetches();
        await _settle();
        buildCursorOfCache(cursor, 1.0, cursor.cache);
        await _settle();
      }
      expect(registered.where((key) => key.contains('_A_')), isNotEmpty);
      expect(registered.where((key) => key.contains('_B_')), isNotEmpty);
    },
  );

  test(
    'a zoom still gets native cursors for shapes that keep decoding late',
    () async {
      final cursor = ffi.cursorModel;
      // An animation whose frames have native cursors at 1.0 only.
      for (final (id, seed) in [('A', 1), ('B', 2)]) {
        await _feed(ffi, id, size: 32, seed: seed);
        buildCursorOfCache(cursor, 1.0, cursor.cache);
        await _settle();
      }
      // At 0.5 each frame is fetched again, and each fetch answers after the next switch.
      ffi.cursor.holdFetches = true;
      for (var i = 0; i < 6; i++) {
        _select(ffi, i.isEven ? 'A' : 'B');
        ffi.cursor.answerFetches();
        await _settle();
        buildCursorOfCache(cursor, 0.5, cursor.cache);
        await _settle();
      }
      expect(
        registered.where(
          (key) => key.contains('_A_') && key.endsWith('_16_16'),
        ),
        isNotEmpty,
      );
      expect(
        registered.where(
          (key) => key.contains('_B_') && key.endsWith('_16_16'),
        ),
        isNotEmpty,
      );
    },
  );

  test(
    'a raster still missing keeps a late restore, whatever was shown meanwhile',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, 'A', size: 32);
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      await _feed(ffi, 'B');
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();

      _select(ffi, 'A');
      ffi.cursor.holdFetches = true;
      buildCursorOfCache(
        cursor,
        0.5,
        cursor.cache,
      ); // no cursor at 0.5: fetched
      buildCursorOfCache(cursor, 1.0, cursor.cache); // 1.0 has one meanwhile
      _select(ffi, 'B');
      ffi.cursor.answerFetches();
      await _settle();
      ffi.cursor.fetched.clear();

      _select(ffi, 'A');
      buildCursorOfCache(cursor, 0.5, cursor.cache);
      await _settle();
      expect(
        ffi.cursor.fetched,
        isEmpty,
        reason: 'its pixels waited for the cursor at 0.5',
      );
      expect(
        registered.where(
          (key) => key.contains('_A_') && key.endsWith('_16_16'),
        ),
        isNotEmpty,
      );
    },
  );

  test(
    'shapes waiting for a native cursor keep their pixels, within the limit',
    () async {
      const max = CursorModel.kRecentShapes;
      for (var i = 0; i <= max + 1; i++) {
        await _feed(ffi, '$i');
      }
      expect(
        ffi.cursorModel.cachedShape('0')!.hasPixels,
        isFalse,
        reason: 'the one waiting longest is let go',
      );
      expect(ffi.cursorModel.cachedShape('1')!.hasPixels, isTrue);
      expect(ffi.cursorModel.cachedShape('$max')!.hasPixels, isTrue);
    },
  );

  test(
    'two animated cursors and the everyday set keep their native cursors',
    () async {
      // Each frame is a shape of its own: 18 for the Windows busy cursor, 23 for
      // KDE Breeze's wait and progress cursors on X11.
      const frames = 23;
      const statics = 12;
      final cursor = ffi.cursorModel;
      final shapes = [
        for (var i = 0; i < statics; i++) 's$i',
        for (var i = 0; i < frames; i++) 'wait$i',
        for (var i = 0; i < frames; i++) 'progress$i',
      ];
      for (var i = 0; i < shapes.length; i++) {
        await _feed(ffi, shapes[i], seed: i);
        buildCursorOfCache(cursor, 1.0, cursor.cache);
        await _settle();
      }
      ffi.cursor.fetched.clear();
      for (final id in shapes) {
        _select(ffi, id);
        buildCursorOfCache(cursor, 1.0, cursor.cache);
        await _settle();
      }
      expect(
        ffi.cursor.fetched,
        isEmpty,
        reason: 'every shape kept its native cursor',
      );
      expect(registered.length, shapes.length);
      expect(deleted, isEmpty);
    },
  );

  test(
    'a shape painted again is decoded again, the last one shown meanwhile',
    () async {
      await _feed(ffi, '1', size: 16);
      await _feed(ffi, '2');
      _select(ffi, '1');
      expect(
        ffi.cursorModel.image?.width,
        8,
        reason: 'shape 2 until 1 is back',
      );
      await _settle();
      expect(ffi.cursor.fetched, ['1']);
      expect(ffi.cursorModel.image?.width, 16);
      expect(ffi.cursorModel.shapeIds, ['1']);
    },
  );

  test(
    'a shape the core gives but that does not decode is asked for once',
    () async {
      await _feed(ffi, '1');
      await _feed(ffi, '2');
      ffi.cursor.core['1'] = CursorShape(
        hotx: 0,
        hoty: 0,
        width: 8,
        height: 8,
        colors: Uint8List(3),
      );
      _select(ffi, '1');
      for (var i = 0; i < 5; i++) {
        ffi.cursorModel.image;
        await _settle();
      }
      expect(ffi.cursor.fetched, ['1']);
    },
  );

  test(
    'a shape switched away from while it decoded is asked for again',
    () async {
      await _feed(ffi, '1', size: 16);
      await _feed(ffi, '2');
      _select(ffi, '1');
      ffi.cursorModel.image; // asks the core
      // The core has answered and the shape is decoding when the peer moves on.
      await Future<void>.delayed(Duration.zero);
      _select(ffi, '2');
      await _settle();
      expect(
        ffi.cursorModel.cachedShape('1')!.hasPixels,
        isTrue,
        reason:
            'decoded after the peer moved on, it waits for its native cursor',
      );
      _select(ffi, '1');
      ffi.cursorModel.image;
      await _settle();
      expect(ffi.cursor.fetched, ['1', '1']);
      expect(ffi.cursorModel.image?.width, 16);
    },
  );

  test('a shape decoded after the session was cleared is not kept', () async {
    await _feed(ffi, '1', size: 16);
    await _feed(ffi, '2');
    _select(ffi, '1');
    ffi.cursorModel.image; // asks the core
    ffi.cursorModel.clear();
    await _settle();
    expect(ffi.cursorModel.shapeIds, isEmpty);
    expect(ffi.cursorModel.cache, isNull);
  });

  test('a shape the core does not have is asked for once', () async {
    await _feed(ffi, '1');
    await _feed(ffi, '2');
    ffi.cursor.core.remove('1');
    _select(ffi, '1');
    for (var i = 0; i < 5; i++) {
      ffi.cursorModel.image;
      await _settle();
    }
    expect(ffi.cursor.fetched, ['1']);
  });

  _registerRecoveryTests();
}
