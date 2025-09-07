import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

typedef DurationPreviewBuilder = Widget Function(Duration time);

class SeekbarChapter {
  final Duration start;
  final String title;

  const SeekbarChapter({required this.start, required this.title});
}

class _SeekbarPainter extends CustomPainter {
  final double minSec;
  final double maxSec;
  final double activeFrac;
  final double bufferedFrac;
  final Color inactiveColor;
  final Color bufferedColor;
  final Color activeColor;
  final double radius;
  final double gap;
  final List<SeekbarChapter> chapters;
  final double? hoveredSec;
  final double hoverExtra;

  _SeekbarPainter({
    required this.minSec,
    required this.maxSec,
    required this.activeFrac,
    required this.bufferedFrac,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.activeColor,
    required this.radius,
    required this.gap,
    required this.chapters,
    this.hoveredSec,
    this.hoverExtra = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    final width = size.width;
    if (width <= 0) return;
    final thickness = size.height;
    final corner = radius.clamp(0.0, thickness / 2);

    if (maxSec <= minSec) {
      final h = thickness;
      final y = (size.height - h) / 2;
      paint.color = inactiveColor;
      final baseRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(0, y, width, h),
        topLeft: Radius.circular(corner),
        bottomLeft: Radius.circular(corner),
        topRight: Radius.circular(corner),
        bottomRight: Radius.circular(corner),
      );
      canvas.drawRRect(baseRect, paint);

      final bx = bufferedFrac.clamp(0.0, 1.0) * width;
      if (bx > 0) {
        paint.color = bufferedColor;
        final bRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(0, y, bx, h),
          topLeft: Radius.circular(corner),
          bottomLeft: Radius.circular(corner),
          topRight: Radius.circular(corner),
          bottomRight: Radius.circular(corner),
        );
        canvas.drawRRect(bRect, paint);
      }

      final ax = activeFrac.clamp(0.0, 1.0) * width;
      if (ax > 0) {
        paint.color = activeColor;
        final aRect = RRect.fromRectAndCorners(
          Rect.fromLTWH(0, y, ax, h),
          topLeft: Radius.circular(corner),
          bottomLeft: Radius.circular(corner),
          topRight: Radius.circular(corner),
          bottomRight: Radius.circular(corner),
        );
        canvas.drawRRect(aRect, paint);
      }

      return;
    }

    final List<double> starts = [];
    if (chapters.isEmpty) {
      starts.add(minSec);
    } else {
      for (final c in chapters) {
        final s = c.start.inSeconds.toDouble().clamp(minSec, maxSec);
        starts.add(s);
      }
      if (starts.first > minSec) starts.insert(0, minSec);
    }
    starts.sort();
    final dedup = <double>[];
    for (final s in starts) {
      if (dedup.isEmpty || (s - dedup.last).abs() > 0.0001) dedup.add(s);
    }
    final boundaries = <double>[...dedup];
    if (boundaries.isEmpty || boundaries.last < maxSec) boundaries.add(maxSec);

    final activeX = (activeFrac.clamp(0.0, 1.0)) * width;
    final bufferedX = (bufferedFrac.clamp(0.0, 1.0)) * width;

    void drawSegment(double x0, double x1, Color color, double segThickness) {
      if (x1 <= x0) return;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
            x0, (size.height - segThickness) / 2, x1 - x0, segThickness),
        topLeft: Radius.circular(corner),
        bottomLeft: Radius.circular(corner),
        topRight: Radius.circular(corner),
        bottomRight: Radius.circular(corner),
      );
      paint.color = color;
      canvas.drawRRect(rect, paint);
    }

    for (var i = 0; i < boundaries.length - 1; i++) {
      final segStartSec = boundaries[i];
      final segEndSec = boundaries[i + 1];
      final fs = (segStartSec - minSec) / (maxSec - minSec);
      final fe = (segEndSec - minSec) / (maxSec - minSec);
      var x0 = (fs.clamp(0.0, 1.0)) * width;
      var x1 = (fe.clamp(0.0, 1.0)) * width;

      final isFirst = i == 0;
      final isLast = i == boundaries.length - 2;
      final halfGap = gap / 2;
      if (!isFirst) x0 += halfGap;
      if (!isLast) x1 -= halfGap;
      if (x1 <= x0) continue;

      final isHovered = hoveredSec != null
          ? (i < boundaries.length - 2
              ? (hoveredSec! >= segStartSec && hoveredSec! < segEndSec)
              : (hoveredSec! >= segStartSec && hoveredSec! <= segEndSec))
          : false;
      final segThickness = thickness + (isHovered ? hoverExtra : 0.0);

      drawSegment(x0, x1, inactiveColor, segThickness);

      final bx1 = bufferedX.clamp(x0, x1);
      if (bx1 > x0) drawSegment(x0, bx1, bufferedColor, segThickness);
      final ax1 = activeX.clamp(x0, x1);
      if (ax1 > x0) drawSegment(x0, ax1, activeColor, segThickness);
    }
  }

  @override
  bool shouldRepaint(covariant _SeekbarPainter old) {
    return minSec != old.minSec ||
        maxSec != old.maxSec ||
        activeFrac != old.activeFrac ||
        bufferedFrac != old.bufferedFrac ||
        inactiveColor != old.inactiveColor ||
        bufferedColor != old.bufferedColor ||
        activeColor != old.activeColor ||
        radius != old.radius ||
        gap != old.gap ||
        hoveredSec != old.hoveredSec ||
        hoverExtra != old.hoverExtra ||
        chapters.length != old.chapters.length ||
        _chaptersChanged(old.chapters);
  }

  bool _chaptersChanged(List<SeekbarChapter> other) {
    if (chapters.length != other.length) return true;
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].start != other[i].start ||
          chapters[i].title != other[i].title) {
        return true;
      }
    }
    return false;
  }
}

class CustomSeekBar extends StatefulWidget {
  final double value;
  final double buffered;
  final double min;
  final double max;

  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color bufferedTrackColor;
  final Color thumbColor;
  final double trackHeight;

  final DurationPreviewBuilder? previewBuilder;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final List<SeekbarChapter> chapters;
  final Color chapterMarkerColor;
  final Color activeChapterMarkerColor;
  final double chapterMarkerWidth;
  final double chapterMarkerExtraHeight;
  final double chapterGap;

  const CustomSeekBar({
    super.key,
    required this.value,
    required this.buffered,
    required this.min,
    required this.max,
    this.activeTrackColor = Colors.red,
    this.inactiveTrackColor = Colors.white24,
    this.bufferedTrackColor = Colors.white38,
    this.thumbColor = Colors.white,
    this.trackHeight = 4.0,
    this.previewBuilder,
    this.onChanged,
    this.onChangeEnd,
    this.chapters = const [],
    this.chapterMarkerColor = const Color(0x66FFFFFF),
    this.activeChapterMarkerColor = Colors.white,
    this.chapterMarkerWidth = 2.0,
    this.chapterMarkerExtraHeight = 6.0,
    this.chapterGap = 3.0,
  });

  @override
  State<CustomSeekBar> createState() => _CustomSeekBarState();
}

class _CustomSeekBarState extends State<CustomSeekBar>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isHovering = false;
  double _hoverValue = 0.0;
  double _smoothedHoverValue = 0.0;
  late final AnimationController _hoverController;

  double get _currentValue => _isDragging ? _dragValue : widget.value;

  double _clamp(double v) => v.clamp(widget.min, widget.max);

  double _dxToValue(Offset localPos, double width) {
    if (width <= 0) return widget.min;
    final t = (localPos.dx / width).clamp(0.0, 1.0);
    return _clamp(widget.min + t * (widget.max - widget.min));
  }

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 160),
    )..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final outerWidth = constraints.maxWidth;
        final range = (widget.max - widget.min).abs();
        final safeRange = range <= 0 ? 1.0 : range;

        final activeFrac =
            ((_currentValue - widget.min) / safeRange).clamp(0.0, 1.0);
        final bufferedFrac =
            ((widget.buffered - widget.min) / safeRange).clamp(0.0, 1.0);

        final thumbRadius = widget.trackHeight * 2.0;
        final previewWidth = 160.0;
        final previewThumbHeight = 90.0;
        final trackWidth =
            (outerWidth - thumbRadius * 2).clamp(0.0, double.infinity);
        final chapters = [...widget.chapters]
          ..sort((a, b) => a.start.compareTo(b.start));
        int activeChapterIndex = -1;
        final starts = <double>[];
        for (final c in chapters) {
          starts
              .add(c.start.inSeconds.toDouble().clamp(widget.min, widget.max));
        }
        if (starts.isEmpty || starts.first > widget.min) {
          starts.insert(0, widget.min);
        }
        starts.sort();

        int chapterIndexForSec(double sec) {
          if (starts.isEmpty) return -1;
          const double biasSec = 0.15;
          double v = (sec + biasSec).clamp(widget.min, widget.max);
          int lo = 0, hi = starts.length;
          while (lo < hi) {
            final mid = (lo + hi) >> 1;
            if (starts[mid] <= v) {
              lo = mid + 1;
            } else {
              hi = mid;
            }
          }
          final idx = (lo - 1).clamp(0, starts.length - 1);
          return idx;
        }

        if (chapters.isNotEmpty) {
          final curSec = widget.min + activeFrac * safeRange;
          activeChapterIndex = chapterIndexForSec(curSec);
        }

        String? previewChapterTitle;
        if (chapters.isNotEmpty && (_isDragging || _isHovering)) {
          final sec = _isDragging ? _currentValue : _hoverValue;
          final idx = chapterIndexForSec(sec);
          if (idx >= 0 && idx < chapters.length) {
            previewChapterTitle = chapters[idx].title;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) {
            setState(() {
              _isDragging = true;
              final dxTrack =
                  (d.localPosition.dx - thumbRadius).clamp(0.0, trackWidth);
              _dragValue = _dxToValue(Offset(dxTrack, 0), trackWidth);
            });
            widget.onChanged?.call(_dragValue);
          },
          onHorizontalDragUpdate: (d) {
            setState(() {
              final dxTrack =
                  (d.localPosition.dx - thumbRadius).clamp(0.0, trackWidth);
              _dragValue = _dxToValue(Offset(dxTrack, 0), trackWidth);
            });
            widget.onChanged?.call(_dragValue);
          },
          onHorizontalDragEnd: (_) {
            setState(() => _isDragging = false);
            widget.onChangeEnd?.call(_currentValue);
          },
          onTapDown: (d) {
            final dxTrack =
                (d.localPosition.dx - thumbRadius).clamp(0.0, trackWidth);
            final v = _dxToValue(Offset(dxTrack, 0), trackWidth);
            widget.onChanged?.call(v);
            widget.onChangeEnd?.call(v);
          },
          child: SizedBox(
            height: thumbRadius * 2.2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: thumbRadius),
              child: MouseRegion(
                onHover: (event) {
                  final dxTrack = event.localPosition.dx.clamp(0.0, trackWidth);
                  final v = _dxToValue(Offset(dxTrack, 0), trackWidth);
                  const thresholdSec = 0.02;
                  final delta = (v - _hoverValue).abs();
                  if (!_isHovering) {
                    _isHovering = true;
                    _hoverValue = v;
                    _smoothedHoverValue = v;
                    _hoverController.forward();
                    setState(() {});
                    return;
                  }
                  _hoverValue = v;
                  if (delta >= thresholdSec) {
                    _smoothedHoverValue =
                        lerpDouble(_smoothedHoverValue, v, 0.65) ?? v;
                  }
                  setState(() {});
                },
                onExit: (_) {
                  if (_isHovering) {
                    _isHovering = false;
                    _hoverController.reverse();
                    setState(() {});
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: SizedBox(
                          width: trackWidth,
                          height: widget.trackHeight,
                          child: CustomPaint(
                            painter: _SeekbarPainter(
                              minSec: widget.min,
                              maxSec: widget.max,
                              activeFrac: activeFrac.toDouble(),
                              bufferedFrac: bufferedFrac.toDouble(),
                              inactiveColor: widget.inactiveTrackColor,
                              bufferedColor: widget.bufferedTrackColor,
                              activeColor: widget.activeTrackColor,
                              radius: 0.0,
                              gap: widget.chapterGap,
                              chapters: chapters,
                              hoveredSec:
                                  _isHovering ? _smoothedHoverValue : null,
                              hoverExtra: (widget.trackHeight * 0.5) *
                                  _hoverController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (chapters.isNotEmpty &&
                        widget.chapterMarkerWidth > 0 &&
                        widget.chapterMarkerExtraHeight > 0)
                      ...chapters.map((c) {
                        final frac =
                            (c.start.inSeconds - widget.min) / safeRange;
                        final clamped = frac.clamp(0.0, 1.0);
                        return Positioned(
                          left: (trackWidth * clamped) -
                              (widget.chapterMarkerWidth / 2),
                          child: Container(
                            width: widget.chapterMarkerWidth,
                            height: widget.trackHeight +
                                widget.chapterMarkerExtraHeight,
                            decoration: BoxDecoration(
                              color: chapters.indexOf(c) == activeChapterIndex
                                  ? widget.activeChapterMarkerColor
                                  : widget.chapterMarkerColor,
                              borderRadius: BorderRadius.circular(
                                  widget.chapterMarkerWidth),
                            ),
                          ),
                        );
                      }),
                    Positioned(
                      left: (trackWidth * activeFrac) - thumbRadius,
                      child: Container(
                        width: thumbRadius * 2,
                        height: thumbRadius * 2,
                        alignment: Alignment.center,
                        child: Container(
                          width: widget.trackHeight + 8,
                          height: widget.trackHeight + 8,
                          decoration: BoxDecoration(
                            color: widget.thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.previewBuilder != null &&
                        (_isDragging || _isHovering))
                      Positioned(
                        left: (() {
                          final frac = _isDragging
                              ? activeFrac
                              : ((_hoverValue - widget.min) / safeRange)
                                  .clamp(0.0, 1.0);
                          final rawLeft =
                              (trackWidth * frac) - (previewWidth / 2);
                          return rawLeft.clamp(0.0, trackWidth - previewWidth);
                        })(),
                        bottom: thumbRadius * 2.2,
                        child: SizedBox(
                          width: previewWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: previewWidth,
                                height: previewThumbHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/test.png',
                                    width: previewWidth,
                                    height: previewThumbHeight,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (previewChapterTitle != null) ...[
                                Text(
                                  previewChapterTitle,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Center(
                                child: widget.previewBuilder!(
                                  Duration(
                                    seconds: (_isDragging
                                            ? _currentValue
                                            : _hoverValue)
                                        .round(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<SeekbarChapter> parseSeekbarChapters(String input) {
  final List<SeekbarChapter> chapters = [];
  final timestampRegex = RegExp(r"(?:(\d{1,2}):)?(\d{1,2}):(\d{2})");

  Duration? parseMatch(RegExpMatch m) {
    final hStr = m.group(1);
    final mStr = m.group(2);
    final sStr = m.group(3);
    if (mStr == null || sStr == null) return null;
    final h = hStr != null ? int.tryParse(hStr) ?? 0 : 0;
    final mi = int.tryParse(mStr) ?? 0;
    final se = int.tryParse(sStr) ?? 0;
    return Duration(hours: h, minutes: mi, seconds: se);
  }

  final matches = timestampRegex.allMatches(input).toList();
  for (var i = 0; i < matches.length; i++) {
    final m = matches[i];
    final startDur = parseMatch(m);
    if (startDur == null) continue;
    final titleStart = m.end;
    final titleEnd =
        i + 1 < matches.length ? matches[i + 1].start : input.length;
    var title = input.substring(titleStart, titleEnd).trim();
    title = title.replaceFirst(RegExp(r"^[\-–—\s:]+"), '').trim();
    if (title.isEmpty) title = 'Chapter';
    chapters.add(SeekbarChapter(start: startDur, title: title));
  }

  if (chapters.isNotEmpty && chapters.first.start > Duration.zero) {
    chapters.insert(
        0, const SeekbarChapter(start: Duration.zero, title: 'Intro'));
  }

  chapters.sort((a, b) => a.start.compareTo(b.start));
  final unique = <int>{};
  final out = <SeekbarChapter>[];
  for (final c in chapters) {
    final key = c.start.inSeconds;
    if (unique.add(key)) out.add(c);
  }
  return out;
}
