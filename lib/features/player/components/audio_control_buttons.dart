import 'package:flutter/material.dart';

class MaterialPlayOrPauseButton extends StatelessWidget {
  final double iconSize;
  final bool isPlaying;
  final VoidCallback onPressed;

  const MaterialPlayOrPauseButton({
    super.key,
    required this.iconSize,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: iconSize,
      ),
      onPressed: onPressed,
    );
  }
}

class MaterialVolumeButton extends StatefulWidget {
  final double iconSize;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const MaterialVolumeButton({
    super.key,
    required this.iconSize,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  State<MaterialVolumeButton> createState() => _MaterialVolumeButtonState();
}

class _MaterialVolumeButtonState extends State<MaterialVolumeButton> {
  bool _showVolumeSlider = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showVolumeSlider = true),
      onExit: (_) {
        if (!_isDragging) {
          setState(() => _showVolumeSlider = false);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              widget.volume <= 0
                  ? Icons.volume_off_rounded
                  : widget.volume < 0.5
                      ? Icons.volume_down_rounded
                      : Icons.volume_up_rounded,
              size: widget.iconSize,
            ),
            onPressed: () {
              if (widget.volume > 0) {
                widget.onVolumeChanged(0);
              } else {
                widget.onVolumeChanged(1);
              }
            },
          ),
          if (_showVolumeSlider)
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: widget.iconSize / 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                ),
                child: Slider(
                  value: widget.volume.clamp(0.0, 1.0),
                  onChanged: widget.onVolumeChanged,
                  onChangeStart: (_) => setState(() => _isDragging = true),
                  onChangeEnd: (_) => setState(() => _isDragging = false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MaterialPositionIndicator extends StatelessWidget {
  final Duration position;
  final Duration duration;

  const MaterialPositionIndicator({
    super.key,
    required this.position,
    required this.duration,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        '${_formatDuration(position)} / ${_formatDuration(duration)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class MaterialSeekBar extends StatefulWidget {
  final double height;
  final Color color;
  final Color activeColor;
  final Color bufferColor;
  final double thumbSize;
  final Color thumbColor;
  final Duration position;
  final Duration duration;
  final VoidCallback onSeekStart;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSeekEnd;

  const MaterialSeekBar({
    super.key,
    required this.height,
    required this.color,
    required this.activeColor,
    required this.bufferColor,
    required this.thumbSize,
    required this.thumbColor,
    required this.position,
    required this.duration,
    required this.onSeekStart,
    required this.onSeek,
    required this.onSeekEnd,
  });

  @override
  State<MaterialSeekBar> createState() => _MaterialSeekBarState();
}

class _MaterialSeekBarState extends State<MaterialSeekBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: widget.height,
        activeTrackColor: widget.activeColor,
        inactiveTrackColor: widget.color,
        thumbColor: widget.thumbColor,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: widget.thumbSize / 2,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
      ),
      child: Slider(
        value: _isDragging
            ? _dragValue
            : widget.position.inMilliseconds.toDouble().clamp(
                  0,
                  widget.duration.inMilliseconds.toDouble(),
                ),
        min: 0,
        max: widget.duration.inMilliseconds.toDouble(),
        onChangeStart: (value) {
          setState(() {
            _isDragging = true;
            _dragValue = value;
          });
          widget.onSeekStart();
        },
        onChanged: (value) {
          setState(() => _dragValue = value);
          widget.onSeek(Duration(milliseconds: value.round()));
        },
        onChangeEnd: (value) {
          setState(() => _isDragging = false);
          widget.onSeekEnd();
        },
      ),
    );
  }
}
