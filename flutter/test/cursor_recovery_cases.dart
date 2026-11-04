part of 'cursor_replay_test.dart';

void _registerRecoveryTests() {
  test(
    'a shape the core lacks is remembered only while it is in use',
    () async {
      await _feed(ffi, '1');
      for (var i = 0; i < 1000; i++) {
        _select(ffi, 'missing$i');
        ffi.cursorModel.image;
      }
      await _settle();
      expect(ffi.cursor.fetched.length, 1000, reason: 'each is asked for once');
      _select(ffi, 'missing0');
      await _settle();
      expect(
        ffi.cursor.fetched.length,
        1001,
        reason: 'nothing is kept for a shape no longer in use',
      );
    },
  );

  test(
    'a shape the core lacks is asked for again after another was in use',
    () async {
      await _feed(ffi, '1');
      _select(ffi, 'missing0');
      await _settle();
      _select(ffi, '1');
      _select(ffi, 'missing0');
      await _settle();
      expect(ffi.cursor.fetched, ['missing0', 'missing0']);
    },
  );

  test(
    'a moved tab carries the id in use, and its window asks the core',
    () async {
      await _feed(ffi, '1', size: 16);
      await _feed(ffi, '2');
      await _feed(ffi, '1', size: 16);
      final carried = ffi.ffiModel.cachedPeerData.toString();
      expect(carried, isNot(contains('colors')));
      expect(
        CachedPeerData.fromString(carried)!.lastCursorId['id'],
        '1',
        reason: 'a shape arriving is the shape in use',
      );

      final moved = _FFI();
      addTearDown(moved.cursorModel.disposeImages);
      moved.cursor.core.addAll(ffi.cursor.core);
      _select(moved, '1');
      await _settle();
      expect(moved.cursor.fetched, ['1']);
      expect(moved.cursorModel.cache?.id, '1');
      expect(moved.cursorModel.image?.width, 16);
    },
  );

  test(
    'a shape keeps a native cursor for each raster it was shown at',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, '1', size: 32);
      for (final scale in [1.0, 0.5, 1.0, 0.5]) {
        buildCursorOfCache(cursor, scale, cursor.cache);
        await _settle();
      }
      expect(registered.length, 2, reason: 'a raster returned to is reused');
      expect(deleted, isEmpty);
      expect(cursor.cachedKeys, registered.toSet());
    },
  );

  test('a cleared session forgets the native cursors it deleted', () async {
    final cursor = ffi.cursorModel;
    await _feed(ffi, '1');
    buildCursorOfCache(cursor, 1.0, cursor.cache);
    await _settle();
    cursor.clear();
    await _settle();
    expect(deleted, registered);
    expect(cursor.cachedKeys, isEmpty);
  });

  test('a tab closing does not delete the cursors of another tab', () async {
    final other = _FFI();
    addTearDown(other.cursorModel.disposeImages);
    while (preDefaultCursor.cache == null) {
      await _settle();
    }
    buildCursorOfCache(ffi.cursorModel, 1.0, preDefaultCursor.cache);
    buildCursorOfCache(other.cursorModel, 1.0, preDefaultCursor.cache);
    await _settle();
    expect(registered.toSet().length, 2, reason: 'each tab has its own');

    ffi.cursorModel.clear();
    await _settle();
    expect(other.cursorModel.cachedKeys.single, isNot(isIn(deleted)));
  });

  test(
    'a shape given as a view into a larger buffer is read from the view',
    () async {
      final pixels = _pixels(8, 3);
      final padded = Uint8List(16 + pixels.length)
        ..setRange(16, 16 + pixels.length, pixels);
      await ffi.ffiModel.handleCursorData(
        '1',
        0,
        0,
        8,
        8,
        Uint8List.sublistView(padded, 16),
      );
      final p = ffi.cursorModel.cache!.image.getPixel(0, 0);
      expect([p.r, p.g, p.b, p.a], [3, 4, 5, 6]);
    },
  );

  test('a shape still decoding leaves the one shown before in place', () async {
    final cursor = ffi.cursorModel;
    await _feed(ffi, '1');
    final shown = _key(buildCursorOfCache(cursor, 1.0, cursor.cache));
    await _settle();
    _select(ffi, '2'); // its shape has not decoded yet
    expect(cursor.cache?.id, '1');
    expect(_key(buildCursorOfCache(cursor, 1.0, cursor.cache)), shown);
    expect(cursor.image, isNotNull);
    await _feed(ffi, '2');
    expect(cursor.cache?.id, '2');
  });

  for (final how in ['does not have', 'cannot decode']) {
    test(
      'a shape the core $how leaves the default cursor, not the one before',
      () async {
        final cursor = ffi.cursorModel;
        await _feed(ffi, '1');
        if (how == 'cannot decode') {
          ffi.cursor.core['2'] = CursorShape(
            hotx: 0,
            hoty: 0,
            width: 8,
            height: 8,
            colors: Uint8List(3),
          );
        }
        _select(ffi, '2');
        expect(cursor.cache?.id, '1', reason: 'kept while the shape may come');
        var notified = 0;
        cursor.addListener(() => notified++);
        await _settle();
        expect(
          cursor.cache,
          isNull,
          reason: 'the desktop shows preDefaultCursor',
        );
        expect(cursor.image, isNull, reason: 'and so does a painted cursor');
        expect(notified, greaterThan(0));
      },
    );
  }

  test('a shape sent that does not decode leaves the default cursor', () async {
    final cursor = ffi.cursorModel;
    await _feed(ffi, '1');
    ffi.cursor.core['2'] = CursorShape(
      hotx: 0,
      hoty: 0,
      width: 8,
      height: 8,
      colors: Uint8List(3),
    );
    await ffi.ffiModel.handleCursorData('2', 0, 0, 8, 8, Uint8List(3));
    expect(cursor.cache, isNull);
    expect(cursor.image, isNull);
    _select(ffi, '2');
    await _settle();
    expect(ffi.cursor.fetched, isEmpty, reason: 'it is not asked for either');
  });

  test(
    'a fetch failing after the session was cleared marks nothing in it',
    () async {
      final cursor = ffi.cursorModel;
      ffi.cursor.holdFetches = true;
      _select(ffi, '1'); // not decoded here yet, so it is asked for
      cursor.clear();
      ffi.cursor.failFetches();
      await _settle();
      ffi.cursor.holdFetches = false;
      _select(ffi, '1'); // the same id, now in the new session
      await _settle();
      expect(ffi.cursor.fetched, ['1', '1']);
    },
  );

  test(
    'a fetch that throws at once tells the listeners after the build',
    () async {
      final cursor = ffi.cursorModel;
      await _feed(ffi, '1');
      ffi.cursor.throwAtOnce = true;
      cursor.id = '2';
      var notified = 0;
      cursor.addListener(() => notified++);
      cursor.restorePixels('2');
      expect(notified, 0, reason: 'a build may be what asked');
      await _settle();
      expect(notified, greaterThan(0));
      expect(cursor.cache, isNull);
    },
  );

  test(
    'a raster still being made falls back to a shape, not the forbidden one',
    () async {
      final cursor = ffi.cursorModel;
      for (var i = 0; preForbiddenCursor.cache == null && i < 100; i++) {
        await _settle();
      }
      expect(preForbiddenCursor.cache, isNotNull);
      await _feed(ffi, '1', size: 32);
      buildCursorOfCache(cursor, 1.0, cursor.cache);
      await _settle();
      await _feed(ffi, '2', size: 32);
      final shown = _key(buildCursorOfCache(cursor, 1.0, cursor.cache));
      await _settle();
      buildCursorOfCache(
        cursor,
        1.0,
        preForbiddenCursor.cache,
      ); // input disabled
      _select(ffi, '1'); // its native cursor held its pixels, so they went
      expect(_key(buildCursorOfCache(cursor, 0.5, cursor.cache)), shown);
    },
  );

  group('a painted cursor', () {
    void painted(String how) {
      if (how == 'mobile') {
        final was = isMobile;
        isMobile = true;
        addTearDown(() => isMobile = was);
      } else {
        ffi.cursor.showRemoteCursor = true;
      }
    }

    for (final how in ['mobile', 'remote cursor shown']) {
      test(
        'keeps the images of two animations and the everyday set ($how)',
        () async {
          painted(how);
          final cursor = ffi.cursorModel;
          final shapes = [
            for (var i = 0; i < 12; i++) 's$i',
            for (var i = 0; i < 23; i++) 'wait$i',
            for (var i = 0; i < 23; i++) 'progress$i',
          ];
          for (var i = 0; i < shapes.length; i++) {
            await _feed(ffi, shapes[i], seed: i);
          }
          for (final id in shapes) {
            _select(ffi, id);
            expect(cursor.shapeIds.last, id, reason: 'its image is at hand');
          }
          await _settle();
          expect(ffi.cursor.fetched, isEmpty);
        },
      );
    }

    test('keeps the images used last, and decodes the others again', () async {
      painted('mobile');
      const max = CursorModel.kRecentShapes;
      final cursor = ffi.cursorModel;
      for (var i = 0; i <= max; i++) {
        await _feed(ffi, '$i');
      }
      expect(cursor.shapeIds.length, max);
      _select(ffi, '$max');
      _select(ffi, '1');
      await _settle();
      expect(ffi.cursor.fetched, isEmpty, reason: 'shape 1 was used lately');
      _select(ffi, '0');
      expect(cursor.image, isNotNull, reason: 'shape 1 until 0 is back');
      await _settle();
      expect(ffi.cursor.fetched, ['0']);
      expect(cursor.shapeIds.length, max);
    });

    test(
      'keeps a shape that finished decoding after the peer moved on',
      () async {
        painted('mobile');
        const max = CursorModel.kRecentShapes;
        final cursor = ffi.cursorModel;
        for (var i = 0; i <= max; i++) {
          await _feed(ffi, '$i');
        }
        _select(ffi, '0');
        cursor.image; // let go, so it is asked for
        await Future<void>.delayed(Duration.zero);
        _select(ffi, '1');
        await _settle();
        _select(ffi, '0');
        cursor.image;
        await _settle();
        expect(ffi.cursor.fetched, ['0'], reason: 'the late one was kept');
        expect(cursor.shapeIds.last, '0');
      },
    );
  });
}
