part of 'custom_key_overlay.dart';

// ignore_for_file: invalid_use_of_protected_member
extension _CustomKeyStorage on CustomKeyOverlayState {
  Future<File> _file() async {
    final filename = _filename;
    return File('${(await getApplicationSupportDirectory()).path}/$filename');
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rows = (data['spots'] as List).cast<Map<String, dynamic>>();
      if (!mounted || generation != _loadGeneration || rows.length > 40) return;
      setState(() {
        _spots = rows.map(_KeySpot.fromJson).toList();
        _visible = data['visible'] != false;
        final positions = data['mousePositions'];
        if (positions is Map) {
          for (final id in ['mouse', 'wheel']) {
            final p = positions[id];
            if (p is List &&
                p.length == 2 &&
                p.every((v) => v is num && v.isFinite)) {
              _mousePositions[id] = Offset(
                (p[0] as num).toDouble().clamp(0, 1),
                (p[1] as num).toDouble().clamp(0, 1),
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint('CustomKeyOverlay using default layout: $e');
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loaded = true);
        widget.onVisibilityChanged?.call(_visible);
      }
    }
  }

  Future<void> _save() {
    final destination = _file();
    final data = jsonEncode({
      'spots': _spots.map((s) => s.toJson()).toList(),
      'visible': _visible,
      'mousePositions': _mousePositions.map(
        (id, p) => MapEntry(id, [p.dx, p.dy]),
      ),
    });
    _pendingSave = _pendingSave.then((_) async {
      try {
        final file = await destination;
        await file.parent.create(recursive: true);
        final temporary = File('${file.path}.tmp');
        await temporary.writeAsString(data, flush: true);
        await temporary.rename(file.path);
      } catch (e) {
        debugPrint('CustomKeyOverlay layout save failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.translate('Could not save key layout')),
            ),
          );
        }
      }
    });
    return _pendingSave;
  }

}
