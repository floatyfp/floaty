import 'package:flutter/material.dart';

/// Theme data for audio controls
class AudioControlsThemeData {
  // BEHAVIOR
  final bool modifyVolumeOnScroll;
  final bool hideMouseOnControlsRemoval;
  final bool playAndPauseOnTap;

  // GENERIC
  final EdgeInsets? padding;
  final Duration controlsHoverDuration;
  final Duration controlsTransitionDuration;

  // BUTTON BAR
  final List<Widget> bottomButtonBar;
  final EdgeInsets bottomButtonBarMargin;
  final double buttonBarHeight;
  final double buttonBarButtonSize;
  final Color buttonBarButtonColor;

  // SEEK BAR
  final Duration seekBarTransitionDuration;
  final Duration seekBarThumbTransitionDuration;
  final EdgeInsets seekBarMargin;
  final double seekBarHeight;
  final double seekBarHoverHeight;
  final double seekBarContainerHeight;
  final Color seekBarColor;
  final Color seekBarHoverColor;
  final Color seekBarPositionColor;
  final Color seekBarBufferColor;
  final double seekBarThumbSize;
  final Color seekBarThumbColor;

  // VOLUME BAR
  final Color volumeBarColor;
  final Color volumeBarActiveColor;
  final double volumeBarThumbSize;
  final Color volumeBarThumbColor;
  final Duration volumeBarTransitionDuration;

  const AudioControlsThemeData({
    this.modifyVolumeOnScroll = true,
    this.hideMouseOnControlsRemoval = false,
    this.playAndPauseOnTap = true,
    this.padding,
    this.controlsHoverDuration = const Duration(seconds: 3),
    this.controlsTransitionDuration = const Duration(milliseconds: 150),
    this.bottomButtonBar = const [],
    this.bottomButtonBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.buttonBarHeight = 56.0,
    this.buttonBarButtonSize = 28.0,
    this.buttonBarButtonColor = const Color(0xFFFFFFFF),
    this.seekBarTransitionDuration = const Duration(milliseconds: 300),
    this.seekBarThumbTransitionDuration = const Duration(milliseconds: 150),
    this.seekBarMargin = const EdgeInsets.symmetric(horizontal: 16.0),
    this.seekBarHeight = 3.2,
    this.seekBarHoverHeight = 5.6,
    this.seekBarContainerHeight = 36.0,
    this.seekBarColor = const Color(0x3DFFFFFF),
    this.seekBarHoverColor = const Color(0x3DFFFFFF),
    this.seekBarPositionColor = const Color(0xFFFF0000),
    this.seekBarBufferColor = const Color(0x3DFFFFFF),
    this.seekBarThumbSize = 12.0,
    this.seekBarThumbColor = const Color(0xFFFF0000),
    this.volumeBarColor = const Color(0x3DFFFFFF),
    this.volumeBarActiveColor = const Color(0xFFFFFFFF),
    this.volumeBarThumbSize = 12.0,
    this.volumeBarThumbColor = const Color(0xFFFFFFFF),
    this.volumeBarTransitionDuration = const Duration(milliseconds: 150),
  });

  AudioControlsThemeData copyWith({
    bool? modifyVolumeOnScroll,
    bool? hideMouseOnControlsRemoval,
    bool? playAndPauseOnTap,
    EdgeInsets? padding,
    Duration? controlsHoverDuration,
    Duration? controlsTransitionDuration,
    List<Widget>? bottomButtonBar,
    EdgeInsets? bottomButtonBarMargin,
    double? buttonBarHeight,
    double? buttonBarButtonSize,
    Color? buttonBarButtonColor,
    Duration? seekBarTransitionDuration,
    Duration? seekBarThumbTransitionDuration,
    EdgeInsets? seekBarMargin,
    double? seekBarHeight,
    double? seekBarHoverHeight,
    double? seekBarContainerHeight,
    Color? seekBarColor,
    Color? seekBarHoverColor,
    Color? seekBarPositionColor,
    Color? seekBarBufferColor,
    double? seekBarThumbSize,
    Color? seekBarThumbColor,
    Color? volumeBarColor,
    Color? volumeBarActiveColor,
    double? volumeBarThumbSize,
    Color? volumeBarThumbColor,
    Duration? volumeBarTransitionDuration,
  }) {
    return AudioControlsThemeData(
      modifyVolumeOnScroll: modifyVolumeOnScroll ?? this.modifyVolumeOnScroll,
      hideMouseOnControlsRemoval:
          hideMouseOnControlsRemoval ?? this.hideMouseOnControlsRemoval,
      playAndPauseOnTap: playAndPauseOnTap ?? this.playAndPauseOnTap,
      padding: padding ?? this.padding,
      controlsHoverDuration:
          controlsHoverDuration ?? this.controlsHoverDuration,
      controlsTransitionDuration:
          controlsTransitionDuration ?? this.controlsTransitionDuration,
      bottomButtonBar: bottomButtonBar ?? this.bottomButtonBar,
      bottomButtonBarMargin: bottomButtonBarMargin ?? this.bottomButtonBarMargin,
      buttonBarHeight: buttonBarHeight ?? this.buttonBarHeight,
      buttonBarButtonSize: buttonBarButtonSize ?? this.buttonBarButtonSize,
      buttonBarButtonColor: buttonBarButtonColor ?? this.buttonBarButtonColor,
      seekBarTransitionDuration:
          seekBarTransitionDuration ?? this.seekBarTransitionDuration,
      seekBarThumbTransitionDuration:
          seekBarThumbTransitionDuration ?? this.seekBarThumbTransitionDuration,
      seekBarMargin: seekBarMargin ?? this.seekBarMargin,
      seekBarHeight: seekBarHeight ?? this.seekBarHeight,
      seekBarHoverHeight: seekBarHoverHeight ?? this.seekBarHoverHeight,
      seekBarContainerHeight:
          seekBarContainerHeight ?? this.seekBarContainerHeight,
      seekBarColor: seekBarColor ?? this.seekBarColor,
      seekBarHoverColor: seekBarHoverColor ?? this.seekBarHoverColor,
      seekBarPositionColor: seekBarPositionColor ?? this.seekBarPositionColor,
      seekBarBufferColor: seekBarBufferColor ?? this.seekBarBufferColor,
      seekBarThumbSize: seekBarThumbSize ?? this.seekBarThumbSize,
      seekBarThumbColor: seekBarThumbColor ?? this.seekBarThumbColor,
      volumeBarColor: volumeBarColor ?? this.volumeBarColor,
      volumeBarActiveColor: volumeBarActiveColor ?? this.volumeBarActiveColor,
      volumeBarThumbSize: volumeBarThumbSize ?? this.volumeBarThumbSize,
      volumeBarThumbColor: volumeBarThumbColor ?? this.volumeBarThumbColor,
      volumeBarTransitionDuration:
          volumeBarTransitionDuration ?? this.volumeBarTransitionDuration,
    );
  }
}

/// Theme provider for audio controls
class AudioControlsTheme extends InheritedWidget {
  final AudioControlsThemeData data;

  const AudioControlsTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static AudioControlsTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AudioControlsTheme>();
  }

  static AudioControlsTheme of(BuildContext context) {
    final AudioControlsTheme? result = maybeOf(context);
    assert(
      result != null,
      'No [AudioControlsTheme] found in [context]',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(AudioControlsTheme oldWidget) =>
      identical(data, oldWidget.data);
}
