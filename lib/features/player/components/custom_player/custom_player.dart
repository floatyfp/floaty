import 'dart:async';
import 'package:floaty/features/player/components/custom_seekbar.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class CustomPlayer extends StatefulWidget {
  final Widget? mediaKitVideo;
  final BetterPlayerController? betterPlayerController;
  final bool isDesktop;
  final bool isFullscreen;
  final String? title;
  final String? subtitle;
  final List<QualityOption>? qualities;
  final List<SubtitleTrack>? subtitles;
  final bool showFullscreenButton;
  final bool showSettingsButton;

  const CustomPlayer({
    super.key,
    this.mediaKitVideo,
    this.betterPlayerController,
    required this.isDesktop,
    this.isFullscreen = false,
    this.title,
    this.subtitle,
    this.qualities,
    this.subtitles,
    this.showFullscreenButton = true,
    this.showSettingsButton = true,
  }) : assert(mediaKitVideo != null || betterPlayerController != null);

  @override
  State<CustomPlayer> createState() => _CustomPlayerState();
}

class _CustomPlayerState extends State<CustomPlayer>
    with TickerProviderStateMixin {
  bool _showControls = true;
  bool _isPlaying = true;
  bool _showSettings = false;
  bool _shouldShowControls =
      true; // Controls whether controls are in the widget tree
  bool _showVolumeSlider = false;
  bool _isDragging = false;
  double _volume = 0.5;
  late AnimationController _volumeAnimationController;
  late Animation<double> _volumeAnimation;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 10); // TODO: Get actual duration

  double _playbackSpeed = 1.0;
  late final AnimationController _animationController;
  Timer? _hideControlsTimer;

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
          // Start a timer to remove from widget tree after fade out
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              setState(() => _shouldShowControls = false);
            }
          });
        });
      }
    });
  }

  void _handleHover(PointerEvent _) {
    if (!_shouldShowControls) {
      setState(() => _shouldShowControls = true);
      // Small delay to ensure the widget is built before starting animation
      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted) {
          setState(() => _showControls = true);
          _startHideTimer();
        }
      });
    } else if (!_showControls) {
      setState(() => _showControls = true);
      _startHideTimer();
    } else {
      _startHideTimer(); // Reset the hide timer on hover
    }
  }

  void _handleExit(PointerEvent _) {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      setState(() => _showControls = false);
      // Schedule removal from widget tree after fade-out animation
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _shouldShowControls = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _volumeAnimationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize with some default values
    _position = Duration.zero;
    _duration = const Duration(hours: 3, minutes: 57, seconds: 21);

    // Initialize volume animation controller
    _volumeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _volumeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _volumeAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    // TODO: Set up listeners for the active player
  }

  // Touch gesture detection
  double _startX = 0.0;
  double _startY = 0.0;
  bool _isSeeking = false;
  double _currentBrightness = 1.0;
  double _currentVolume = 1.0;

  void _handleDragStart(DragStartDetails details) {
    _startX = details.localPosition.dx;
    _startY = details.localPosition.dy;
    _isSeeking = false;
  }

  void _handleDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }

    final dx = details.localPosition.dx - _startX;
    final dy = details.localPosition.dy - _startY;

    // Horizontal swipe for seeking
    if (!_isSeeking && dx.abs() > 20) {
      _isSeeking = true;
    }

    if (_isSeeking) {
      // Calculate seek amount (e.g., 1 second per 50 pixels)
      final seekSeconds = (dx / 50).round();
      if (seekSeconds != 0) {
        _seek(seconds: seekSeconds);
        _startX = details.localPosition.dx;
      }
    }

    // Vertical swipe on left side for brightness
    if (details.localPosition.dx < MediaQuery.of(context).size.width * 0.3) {
      // Adjust brightness (invert dy so swipe up increases brightness)
      _currentBrightness = (_currentBrightness - (dy / 500)).clamp(0.1, 1.0);
      if (widget.betterPlayerController != null) {
        widget.betterPlayerController!.setVolume(_currentVolume);
      }
      // TODO: Implement brightness control for MediaKit
    }
    // Vertical swipe on right side for volume
    else if (details.localPosition.dx >
        MediaQuery.of(context).size.width * 0.7) {
      // Adjust volume (invert dy so swipe up increases volume)
      _currentVolume = (_currentVolume - (dy / 500)).clamp(0.0, 1.0);
      if (widget.betterPlayerController != null) {
        widget.betterPlayerController!.setVolume(_currentVolume);
      }
      // TODO: Implement volume control for MediaKit
    }
  }

  void _handleDragEnd(DragEndDetails _) {
    _isSeeking = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final isMobile = !widget.isDesktop;

        // Start the hide timer when controls are first shown
        if (_showControls) _startHideTimer();

        return MouseRegion(
          onHover: _handleHover,
          onExit: _handleExit,
          child: GestureDetector(
            onDoubleTap: isMobile ? _togglePlayPause : null,
            onHorizontalDragStart: isMobile ? _handleDragStart : null,
            onHorizontalDragUpdate:
                isMobile ? (d) => _handleDragUpdate(d, context) : null,
            onVerticalDragStart: isMobile ? _handleDragStart : null,
            onVerticalDragUpdate:
                isMobile ? (d) => _handleDragUpdate(d, context) : null,
            onHorizontalDragEnd: isMobile ? _handleDragEnd : null,
            onVerticalDragEnd: isMobile ? _handleDragEnd : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.blue,
              child: Stack(
                fit: widget.isFullscreen
                    ? StackFit.expand
                    : StackFit.passthrough,
                children: [
                  // Video display
                  // Positioned.fill(
                  //   child: Center(
                  //     child: AspectRatio(
                  //       aspectRatio: 16 / 9,
                  //       child: _buildVideoPlayer(),
                  //     ),
                  //   ),
                  // ),

                  // Controls overlay - Only in widget tree when needed
                  if (_shouldShowControls)
                    _buildControlsOverlay(isLandscape: isLandscape),

                  // Settings panel
                  if (_showSettings) _buildSettingsPanel(),

                  // Seek indicator for mobile
                  if (_isSeeking && isMobile)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.mediaKitVideo != null) {
      return widget.mediaKitVideo!;
    } else if (widget.betterPlayerController != null) {
      return BetterPlayer(controller: widget.betterPlayerController!);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildControlsOverlay({required bool isLandscape}) {
    final isMobile = !widget.isDesktop;
    final isCompact = isMobile && !widget.isFullscreen;

    // Handle compact mode
    if (isCompact && !_showSettings) {
      return const SizedBox.shrink();
    }

    // Only render the controls if they should be shown
    if (!_shouldShowControls && !_showSettings) {
      return const SizedBox.shrink();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showControls || _showSettings
          ? Container(
              key: ValueKey<bool>(_showControls || _showSettings),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top bar
                  if (!isCompact) _buildTopBar(),

                  // Center controls (only for fullscreen/mobile)
                  if (widget.isFullscreen || !isMobile)
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (widget.isDesktop || widget.isFullscreen) ...[
                              _buildControlButton(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                _togglePlayPause,
                                size: 45,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Bottom bar - only show in fullscreen or if not in compact mode
                  if (!isCompact || widget.isFullscreen)
                    _buildBottomBar(
                      isCompact: isCompact,
                      isLandscape: isLandscape,
                    ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              // TODO: Handle back button
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool isCompact, required bool isLandscape}) {
    // Parse chapters once and compute current chapter title
    final chapters = parseSeekbarChapters(r'''
                  [0:00] Chapters. [2:10] Intro. [2:54] Topic #1: Trump's 100% tech tariffs, demands Intel's CEO to step down. > 4:07 Foxconn, Pal Gelsinger & hockey analogy, Intel & AMD. > 16:45 Less amount of Las Vegas tourism, gambling, airline layoffs. > 21:11 Recession, West Edmonton mall, luxury goods, Linus's brother. > 38:02 "I'm not gay," water park. [42:10] Topic #2: AI topics. > 42:22 Google DeepMind's Genie 3. > 45:14 OpenAI's free GPT models, ChatGPT-5. > 51:55 "ChatGPT lies," MM on Luke's DualSense, Dan's response. > 57:50 Training a model on WAN Show transcript for MM? > 59:35 Luke on why ChatGPT-5 was more interesting than 4/4o. > 1:00:23 Anthropic's Claude Opus 4.1, Elevenlabs's AI generated music. > 1:06:45 Twitter's Grok AI will now have built in ads. > 1:09:43 Luke on LTT's upcoming vibe coding video. [1:12:17] LTTStore's new CPU fidget spinner. > 1:15:13 Taking off the spinner to replace it. [1:17:15] Merch Message #1. > 1:18:02 Why did LTT go for orange? ft. Scrapyard wars. [1:21:12] LTTStore's new screwdriver grip tape. > 1:25:36 LTTStore's new sticker pack. [1:27:16] Topic #3: $3.5m tech jet plane? > 1:29:39 Another jet listing, old laptop, photo staging, limited quantity. [1:39:48] Sponsors ft. Spinning the CPU the whole time. > 1:40:08 Odoo. > 1:41:05 Proton. > 1:41:55 Vessi. [1:43:44] LibreDrive's firmware hack for BLU-ray drives ft. Edmonton. [1:49:23] Scrapyard Wars 10 going live on FP. > 1:50:47 Upcoming extras & BTS footage, FP x Sarah stream. [1:52:15] Topic #4: Tesla autopilot partially liable in a lethal crash. > 1:59:26 Luke on a company using on premise servers for LLMs. > 2:03:34 Would AI have a real impact on health? ft. Lina Khan. [2:06:21] Topic #5: Ubiquiti's UniFi OS server can be ran on PC hardware. [2:09:26] Topic #6: Google claims AI summary doesn't reduce site clicks. > 2:12:11 TMB, blockchain, "post-COVID sources," search engines. > 2:15:32 Linus runs GrapheneOS, DuckDuckGo, Luke on spam calls. [2:21:01] Topic #7: Genshin Impact discontinued on PS4. > 2:30:53 Among Us was a spin-off, Hand and Foot & Canasta. [2:34:23] Topic #8: Instagram added Maps with locations on by default. [2:38:39] Topic #9: Microsoft's vision of computing in 2030. [2:41:47] Topic #10: Digital Foundry bought back & goes independent. > 2:43:12 Freedoms LTT has as an independent media? > 2:55:46 Why does Gaben get a billionaire pass? ft. Amazon, Operah. > 3:04:44 FP poll: Gamer jet or gamer yacht? Gamer ski lift. [3:07:32] Topic #11: Nvidia's chips don't have backdoors or kill switches. [3:07:58] Topic #12: TikTok Pro & Sunshine programme. [3:10:26] Merch Messages #2 ft. After Dark, Luke turns purple. > 3:12:22 How much minimum storage is needed in 2025? > 3:13:42 New games you're anticipating? ft. Carpoon. > 3:16:46 Flagrant case of corruption you've seen in Vancouver? > 3:17:48 Thoughts on wealth flexing YTbers & kids? ft. Weird AI ad. > 3:29:14 Has Luke seen Paco the Parrot? > 3:31:12 LTT bits influenced Hacksmith's mutlitool ft. Colebar. > 3:36:27 What made LTT backpack have an internal bottle holder? > 3:37:57 How did LTT get this many CPUs for the spinner? > 3:38:42 Does Linus teach his kids about online safety? > 3:39:20 Linus's badminton shoes wear. > 3:40:07 Why is there no 24-25 Zenbook Duo laptop reviews? > 3:41:28 As a grinder, what helps Luke relax & feel better? > 3:43:53 Did Linus intend to make the meme face, or he had a resting one? > 3:45:02 Will Linus encourage his kids to pursue education & work? > 3:49:46 Linus's thoughts on working on the hobby farm as an adult? > 3:52:05 Given the Z Fold 7, will Linus daily drive a foldable again? > 3:52:33 Furthest you traveled to view or buy a product? [3:56:33] Outro.
                ''');
    String? currentChapterTitle;
    if (chapters.isNotEmpty) {
      final curSec = _position.inSeconds.toDouble();
      for (int i = chapters.length - 1; i >= 0; i--) {
        final startSec = chapters[i].start.inSeconds.toDouble();
        if (curSec >= startSec) {
          currentChapterTitle = chapters[i].title;
          break;
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isLandscape ? 12.0 : 8.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSeekBar(
                value: _position.inSeconds.toDouble(),
                buffered: _duration.inSeconds.toDouble() / 2,
                min: 0,
                max: _duration.inSeconds.toDouble(),
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.white24,
                bufferedTrackColor: Colors.white38,
                thumbColor: Colors.white,
                trackHeight: 4.0,
                previewBuilder: (time) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Builder(builder: (_) {
                      final h = time.inHours;
                      final m = time.inMinutes.remainder(60);
                      final s = time.inSeconds.remainder(60);
                      final mm = m.toString().padLeft(2, '0');
                      final ss = s.toString().padLeft(2, '0');
                      final text = h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
                      return Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  );
                },
                onChanged: (value) {
                  setState(() {
                    _position = Duration(seconds: value.toInt());
                  });
                },
                onChangeEnd: (value) {
                  // TODO: Implement seek functionality with your video controller
                  // Example: _controller.seek(Duration(seconds: value.toInt()));
                },
                chapterMarkerWidth: 0,
                chapterMarkerExtraHeight: 0,
                chapters: chapters,
                chapterGap: 1,
              )),

          // Bottom controls
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 28.0 : 18.0,
            ),
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  // Left side controls
                  if (!isCompact) ...[
                    _buildControlButton(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      _togglePlayPause,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    _buildVolumeButtonAndSlider(),
                  ] else
                    ...[],

                  // Time display
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Current chapter dot and title (only when chapters exist)
                  if (chapters.isNotEmpty && currentChapterTitle != null) ...[
                    const Icon(
                      Icons.circle,
                      size: 6,
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        currentChapterTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Settings button
                  if (!isCompact && widget.showSettingsButton)
                    _buildControlButton(
                      Icons.settings,
                      _toggleSettings,
                      size: 24,
                    ),

                  // Fullscreen button
                  if (widget.showFullscreenButton) ...[
                    const SizedBox(width: 8),
                    _buildControlButton(
                      widget.isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      _toggleFullscreen,
                      size: 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsHeader('Playback Speed'),
            _buildSpeedOption(0.5),
            _buildSpeedOption(0.75),
            _buildSpeedOption(1.0, isSelected: true),
            _buildSpeedOption(1.25),
            _buildSpeedOption(1.5),
            _buildSpeedOption(2.0),
            const Divider(height: 1, color: Colors.white24),
            _buildSettingsHeader('Quality'),
            if (widget.qualities != null)
              ...widget.qualities!.map((q) => _buildQualityOption(q)),
            if (widget.subtitles != null) ...[
              const Divider(height: 1, color: Colors.white24),
              _buildSettingsHeader('Subtitles'),
              _buildSubtitleOption('Off', isSelected: true),
              ...widget.subtitles!.map((s) => _buildSubtitleOption(s.name)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSpeedOption(double speed, {bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setPlaybackSpeed(speed),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.red : Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text(
                '${speed}x',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (speed == 1.0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityOption(QualityOption quality) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setQuality(quality),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.check,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text(
                quality.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleOption(String label, {bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setSubtitleTrack(label == 'Off' ? null : label),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.red : Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarButton(String label, IconData icon) {
    return TextButton.icon(
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        // TODO: Handle button press
      },
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed,
      {double size = 24}) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: size),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: onPressed,
    );
  }

  Widget _buildVolumeButtonAndSlider() {
    return MouseRegion(
      onEnter: (_) => setState(() => _showVolumeSlider = true),
      onExit: (_) => setState(() => _showVolumeSlider = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _volume == 0
                  ? Icons.volume_off_rounded
                  : _volume <= 0.4
                      ? Icons.volume_mute_rounded
                      : _volume >= 0.65
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
              key: ValueKey<double>(_volume),
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              if (_volume > 0) {
                setState(() => _volume = 0);
              } else {
                setState(() => _volume = 1);
              }
            },
          ),
          AnimatedOpacity(
            opacity: _showVolumeSlider ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _showVolumeSlider ? 60 : 0,
              curve: Curves.easeInOut,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                ),
                child: Slider(
                  value: _volume.clamp(0.0, 1.0),
                  onChanged: (value) {
                    setState(() => _volume = value);
                  },
                  onChangeStart: (_) => setState(() => _isDragging = true),
                  onChangeEnd: (_) => setState(() => _isDragging = false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  // Player control methods
  // This method is kept as it might be used by other parts of the code
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (widget.betterPlayerController != null) {
        if (_isPlaying) {
          widget.betterPlayerController!.play();
        } else {
          widget.betterPlayerController!.pause();
        }
      } else if (widget.mediaKitVideo != null) {
        // TODO: Implement play/pause for MediaKit
        // This would involve using the MediaKit player's play/pause methods
      }
    });
  }

  void _seek({int? seconds, bool rewind = false}) {
    if (widget.betterPlayerController != null) {
      final currentPosition = _position.inSeconds;
      final newPosition = (seconds != null
              ? currentPosition + seconds
              : rewind
                  ? currentPosition - 10
                  : currentPosition + 10)
          .clamp(0, _duration.inSeconds);

      widget.betterPlayerController!.seekTo(Duration(seconds: newPosition));
      setState(() {
        _position = Duration(seconds: newPosition);
      });
    } else if (widget.mediaKitVideo != null) {
      // Implementation for MediaKit
      final currentPosition = _position.inSeconds;
      final newPosition = (seconds != null
              ? currentPosition + seconds
              : rewind
                  ? currentPosition - 10
                  : currentPosition + 10)
          .clamp(0, _duration.inSeconds);

      // TODO: Implement seek for MediaKit using widget.mediaKitVideo
      setState(() {
        _position = Duration(seconds: newPosition);
      });
    }
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
  }

  void _toggleFullscreen() {
    // TODO: Toggle fullscreen
  }

  void _setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    // TODO: Update player speed
  }

  void _setQuality(QualityOption quality) {
    // TODO: Update quality
  }

  void _setSubtitleTrack(String? trackId) {
    // TODO: Update subtitle track
  }
}

class QualityOption {
  final String label;
  final String value;

  const QualityOption({
    required this.label,
    required this.value,
  });
}

class SubtitleTrack {
  final String id;
  final String name;
  final String? language;

  const SubtitleTrack({
    required this.id,
    required this.name,
    this.language,
  });
}
