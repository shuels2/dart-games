import 'package:flutter/material.dart';

import '../../models/player.dart';

/// Face-landmarks inspector + manual editor.
///
/// Shows the player's photo with draggable colored markers overlaid for each
/// landmark (left eye / right eye / nose tip / mouth center) plus a 4-corner
/// draggable bounding box. Each marker has a per-landmark toggle in the
/// right-hand panel; toggling off hides the marker but keeps its value.
///
/// Derived markers (`headTop`, `chinBottom`) are computed from the bounding
/// box and shown as read-only indicators when toggled on.
///
/// The widget keeps a local working copy of the landmarks map; `Save` calls
/// [onSave] with the working copy. `Reset` discards local edits.
class FaceLandmarkInspector extends StatefulWidget {
  final Player player;

  /// Resolved URL/path the widget can pass to `Image.network` (web) or
  /// `Image.file` to render the photo. For server-uploaded photos this is
  /// typically `<base>/api/v1/players/<id>/photo`.
  final String photoUrl;

  /// Called when the user taps Save. Receives the working-copy landmarks.
  /// The caller is responsible for persistence.
  final Future<void> Function(Map<String, dynamic> landmarks) onSave;

  /// Called when the user taps Re-detect. Should re-run mediapipe and
  /// return the fresh landmarks (which replace the working copy).
  final Future<Map<String, dynamic>> Function()? onRedetect;

  const FaceLandmarkInspector({
    super.key,
    required this.player,
    required this.photoUrl,
    required this.onSave,
    this.onRedetect,
  });

  @override
  State<FaceLandmarkInspector> createState() => _FaceLandmarkInspectorState();
}

// ─── Landmark schema ─────────────────────────────────────────────────────────

class _PointLandmark {
  final String key;
  final String label;
  final Color color;
  const _PointLandmark(this.key, this.label, this.color);
}

const List<_PointLandmark> _kPointLandmarks = [
  _PointLandmark('leftEye', 'Left eye', Color(0xFF2196F3)),
  _PointLandmark('rightEye', 'Right eye', Color(0xFF03A9F4)),
  _PointLandmark('noseTip', 'Nose tip', Color(0xFF4CAF50)),
  _PointLandmark('mouthCenter', 'Mouth center', Color(0xFFE91E63)),
];

const Color _kBoundingBoxColor = Color(0xFFFFC107);
const Color _kDerivedColor = Color(0xFFFF9800);

// Default landmarks used when the player has none stored — gives the user
// something to drag instead of an empty image.
const Map<String, dynamic> _kDefaultLandmarks = {
  'boundingBox': {'x': 0.20, 'y': 0.15, 'width': 0.60, 'height': 0.70},
  'leftEye': {'x': 0.38, 'y': 0.40},
  'rightEye': {'x': 0.62, 'y': 0.40},
  'noseTip': {'x': 0.50, 'y': 0.55},
  'mouthCenter': {'x': 0.50, 'y': 0.70},
};

class _FaceLandmarkInspectorState extends State<FaceLandmarkInspector> {
  late Map<String, dynamic> _working;
  late Map<String, dynamic> _original;
  final Map<String, bool> _visible = {
    'boundingBox': true,
    'leftEye': true,
    'rightEye': true,
    'noseTip': true,
    'mouthCenter': true,
    'headTop': true,
    'chinBottom': true,
  };
  bool _busy = false;
  String? _error;

  // Drag tracking — see the matching pattern in TreasureMapWidget.
  // The key is attached to the Stack that hosts the markers so we
  // can convert global touch positions into canvas-local coords on
  // every drag event. Absolute positioning means the marker tracks
  // the mouse pointer 1:1 even when multiple gesture events fire
  // between rebuilds (the previous delta-based code only moved by
  // the LAST frame's delta when events batched).
  final GlobalKey _canvasKey = GlobalKey();
  // Offset from the touch to the marker center, captured at drag
  // start so the marker keeps its relative position under the cursor.
  Offset _dragStartOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _original = _deepCopy(widget.player.faceLandmarks ?? _kDefaultLandmarks);
    _working = _deepCopy(_original);
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> src) {
    return src.map((k, v) {
      if (v is Map) {
        return MapEntry(k, Map<String, dynamic>.from(v as Map));
      }
      return MapEntry(k, v);
    });
  }

  bool get _dirty {
    return _original.toString() != _working.toString();
  }

  void _resetToOriginal() {
    setState(() {
      _working = _deepCopy(_original);
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_working);
      _original = _deepCopy(_working);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Save failed: $e';
        });
      }
    }
  }

  Future<void> _redetect() async {
    if (widget.onRedetect == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Re-detect landmarks?'),
        content: const Text(
          'This replaces your in-progress edits with a fresh detection '
          'from mediapipe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Re-detect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fresh = await widget.onRedetect!();
      setState(() {
        _working = _deepCopy(fresh);
        _original = _deepCopy(fresh);
        _busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Re-detect failed: $e';
        });
      }
    }
  }

  // ── Working-copy mutators (all clamp to 0..1) ──────────────────────────────

  void _setPoint(String key, double nx, double ny) {
    setState(() {
      _working[key] = {
        'x': nx.clamp(0.0, 1.0),
        'y': ny.clamp(0.0, 1.0),
      };
    });
  }

  void _setBoundingBoxCorner(_BboxCorner corner, double nx, double ny) {
    setState(() {
      final bb = Map<String, dynamic>.from(_working['boundingBox'] as Map);
      double x = (bb['x'] as num).toDouble();
      double y = (bb['y'] as num).toDouble();
      double w = (bb['width'] as num).toDouble();
      double h = (bb['height'] as num).toDouble();
      final nxC = nx.clamp(0.0, 1.0);
      final nyC = ny.clamp(0.0, 1.0);

      switch (corner) {
        case _BboxCorner.topLeft:
          final right = x + w;
          final bottom = y + h;
          x = nxC.clamp(0.0, right - 0.02);
          y = nyC.clamp(0.0, bottom - 0.02);
          w = right - x;
          h = bottom - y;
          break;
        case _BboxCorner.topRight:
          final bottom = y + h;
          y = nyC.clamp(0.0, bottom - 0.02);
          h = bottom - y;
          w = (nxC - x).clamp(0.02, 1.0 - x);
          break;
        case _BboxCorner.bottomLeft:
          final right = x + w;
          x = nxC.clamp(0.0, right - 0.02);
          w = right - x;
          h = (nyC - y).clamp(0.02, 1.0 - y);
          break;
        case _BboxCorner.bottomRight:
          w = (nxC - x).clamp(0.02, 1.0 - x);
          h = (nyC - y).clamp(0.02, 1.0 - y);
          break;
      }
      _working['boundingBox'] = {'x': x, 'y': y, 'width': w, 'height': h};
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _buildPhotoArea()),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 2, child: _buildToggleSidebar()),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.face_retouching_natural),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Face mapping — ${widget.player.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoArea() {
    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Stack: image fills, markers positioned in stack pixels.
          // The GlobalKey lets the drag handlers convert global touch
          // positions into stack-local coords (so the marker tracks
          // the mouse pointer 1:1 instead of moving by per-event
          // deltas, which lose ground when events batch between
          // rebuilds).
          return Stack(
            key: _canvasKey,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Image.network(
                  widget.photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'Could not load photo',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
              // The markers anchor to the photo bounds. With BoxFit.contain
              // the image may be letterboxed; we approximate by treating the
              // available constraints as the marker canvas. This matches the
              // way mediapipe's normalized coords are already relative to the
              // image's content rect (full bleed at upload).
              _buildMarkerOverlay(
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMarkerOverlay(Size size) {
    final children = <Widget>[];

    // Bounding box outline (only when visible).
    if (_visible['boundingBox'] == true) {
      final bb = _working['boundingBox'] as Map;
      final left = (bb['x'] as num).toDouble() * size.width;
      final top = (bb['y'] as num).toDouble() * size.height;
      final width = (bb['width'] as num).toDouble() * size.width;
      final height = (bb['height'] as num).toDouble() * size.height;
      children.add(Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: _kBoundingBoxColor, width: 2),
            ),
          ),
        ),
      ));
      for (final corner in _BboxCorner.values) {
        children.add(_buildBboxHandle(corner, size));
      }
    }

    // Point landmarks (eyes / nose / mouth).
    for (final lm in _kPointLandmarks) {
      if (_visible[lm.key] != true) continue;
      final v = _working[lm.key] as Map?;
      if (v == null) continue;
      final px = (v['x'] as num).toDouble() * size.width;
      final py = (v['y'] as num).toDouble() * size.height;
      children.add(_buildDraggableDot(
        key: lm.key,
        label: lm.label,
        color: lm.color,
        center: Offset(px, py),
        canvas: size,
        onMoved: (nx, ny) => _setPoint(lm.key, nx, ny),
      ));
    }

    // Derived markers (read-only).
    if (_visible['headTop'] == true) {
      final bb = _working['boundingBox'] as Map;
      final cx = ((bb['x'] as num) + (bb['width'] as num) / 2) * size.width;
      final cy =
          ((bb['y'] as num) - (bb['height'] as num) * 0.15) * size.height;
      children.add(_buildIndicator(
          'Head top', Offset(cx, cy), _kDerivedColor, size));
    }
    if (_visible['chinBottom'] == true) {
      final bb = _working['boundingBox'] as Map;
      final cx = ((bb['x'] as num) + (bb['width'] as num) / 2) * size.width;
      final cy = ((bb['y'] as num) + (bb['height'] as num)) * size.height;
      children.add(_buildIndicator(
          'Chin bottom', Offset(cx, cy), _kDerivedColor, size));
    }

    return Positioned.fill(child: Stack(children: children));
  }

  Widget _buildDraggableDot({
    required String key,
    required String label,
    required Color color,
    required Offset center,
    required Size canvas,
    required void Function(double nx, double ny) onMoved,
  }) {
    const double dotSize = 18;
    return Positioned(
      left: center.dx - dotSize / 2,
      top: center.dy - dotSize / 2,
      width: dotSize,
      height: dotSize,
      child: GestureDetector(
        key: Key('face-landmark-dot-$key'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final box = _canvasKey.currentContext?.findRenderObject()
              as RenderBox?;
          if (box == null) return;
          final localTouch = box.globalToLocal(details.globalPosition);
          _dragStartOffset = center - localTouch;
        },
        onPanUpdate: (details) {
          final box = _canvasKey.currentContext?.findRenderObject()
              as RenderBox?;
          if (box == null) return;
          final localTouch = box.globalToLocal(details.globalPosition);
          final newCenter = localTouch + _dragStartOffset;
          final nx = (newCenter.dx / canvas.width).clamp(0.0, 1.0);
          final ny = (newCenter.dy / canvas.height).clamp(0.0, 1.0);
          onMoved(nx, ny);
        },
        child: Tooltip(
          message: label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.65),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBboxHandle(_BboxCorner corner, Size canvas) {
    final bb = _working['boundingBox'] as Map;
    final x = (bb['x'] as num).toDouble() * canvas.width;
    final y = (bb['y'] as num).toDouble() * canvas.height;
    final w = (bb['width'] as num).toDouble() * canvas.width;
    final h = (bb['height'] as num).toDouble() * canvas.height;
    late Offset center;
    switch (corner) {
      case _BboxCorner.topLeft:
        center = Offset(x, y);
        break;
      case _BboxCorner.topRight:
        center = Offset(x + w, y);
        break;
      case _BboxCorner.bottomLeft:
        center = Offset(x, y + h);
        break;
      case _BboxCorner.bottomRight:
        center = Offset(x + w, y + h);
        break;
    }
    const double handleSize = 16;
    return Positioned(
      left: center.dx - handleSize / 2,
      top: center.dy - handleSize / 2,
      width: handleSize,
      height: handleSize,
      child: GestureDetector(
        key: Key('face-landmark-bbox-${corner.name}'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          final box = _canvasKey.currentContext?.findRenderObject()
              as RenderBox?;
          if (box == null) return;
          final localTouch = box.globalToLocal(details.globalPosition);
          _dragStartOffset = center - localTouch;
        },
        onPanUpdate: (details) {
          final box = _canvasKey.currentContext?.findRenderObject()
              as RenderBox?;
          if (box == null) return;
          final localTouch = box.globalToLocal(details.globalPosition);
          final newCenter = localTouch + _dragStartOffset;
          final nx = (newCenter.dx / canvas.width).clamp(0.0, 1.0);
          final ny = (newCenter.dy / canvas.height).clamp(0.0, 1.0);
          _setBoundingBoxCorner(corner, nx, ny);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kBoundingBoxColor,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(
    String label,
    Offset center,
    Color color,
    Size canvas,
  ) {
    const double size = 14;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: Tooltip(
          message: label,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.4),
              border: Border.all(color: Colors.white70, width: 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSidebar() {
    final items = <Widget>[
      _toggleRow('boundingBox', 'Bounding box', _kBoundingBoxColor),
      ..._kPointLandmarks.map((lm) => _toggleRow(lm.key, lm.label, lm.color)),
      const Divider(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Text(
          'Derived (from bounding box)',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
      _toggleRow('headTop', 'Head top', _kDerivedColor),
      _toggleRow('chinBottom', 'Chin bottom', _kDerivedColor),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ...items,
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: OutlinedButton.icon(
            key: const Key('face-landmark-reset'),
            onPressed: _dirty && !_busy ? _resetToOriginal : null,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to original'),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.onRedetect != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _redetect,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Re-detect with mediapipe'),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _toggleRow(String key, String label, Color color) {
    return InkWell(
      onTap: _busy
          ? null
          : () => setState(() {
                _visible[key] = !(_visible[key] ?? true);
              }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              key: Key('face-landmark-toggle-$key'),
              value: _visible[key] ?? true,
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                        _visible[key] = v ?? true;
                      }),
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(label)),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.black26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('face-landmark-save'),
            onPressed: _busy || !_dirty ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save mapping'),
          ),
        ],
      ),
    );
  }
}

enum _BboxCorner { topLeft, topRight, bottomLeft, bottomRight }
