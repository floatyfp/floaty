import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:floaty/features/whenplane/repositories/whenplaneintergration.dart';
import 'package:floaty/settings.dart';
import 'package:floaty/shared/views/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class WhenplaneScreen extends StatefulWidget {
  const WhenplaneScreen({super.key, this.v = false, this.h});
  final bool v;
  final double? h;

  @override
  State<WhenplaneScreen> createState() => _WhenplaneScreenState();
}

class _WhenplaneScreenState extends State<WhenplaneScreen> {
  // Countdown timer
  Timer? _timer;
  Timer? _phraseTimer;
  String phrase = whenPlaneIntegration.newPhrase();
  late String jsonData;
  late String latenessData;
  bool isLoading = true;

  bool votingrevealed = true;
  String? selectedVote;
  late String k;

  // Generate random votes for testing
  final votes = [
    {'name': 'On Time', 'votes': Random().nextInt(100) + 1},
    {'name': '5 min', 'votes': Random().nextInt(100) + 1},
    {'name': '10 min', 'votes': Random().nextInt(100) + 1},
    {'name': '15 min', 'votes': Random().nextInt(100) + 1},
    {'name': '20+ min', 'votes': Random().nextInt(100) + 1},
  ];
  late int totalVotes;

  @override
  void initState() {
    super.initState();
    loadSelectedVote();
    websocketStart();
    initFetch();
    _startTimer();

    // Calculate total votes
    totalVotes = votes.fold(0, (sum, vote) => sum + (vote['votes'] as int));
  }

  void initFetch() async {
    jsonData = await whenPlaneIntegration.aggregate();
    latenessData = await whenPlaneIntegration.lateness();
    platenessData = jsonDecode(latenessData);
    pjsonData = jsonDecode(jsonData);
    if (jsonData is Map ||
        latenessData is Map ||
        jsonDecode(jsonData)['error'] != null ||
        jsonDecode(latenessData)['error'] != null) {
      if (mounted) {
        setState(() {
          error = true;
        });
      }
    } else {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            error = false;
            isLoading = false;
          });
        });
      }
    }
  }

  void websocketStart() async {
    // final stream = whenPlaneIntegration.streamWebsocket();
    // stream.listen((message) {
    //   if (message != 'pong') {
    //     if (mounted) {
    //       setState(() {
    //         error = false;
    //         isLoading = false;
    //         jsonData = message;
    //         pjsonData = jsonDecode(message);
    //       });
    //     }
    //   }
    // });
    final aggregate = await whenPlaneIntegration.aggregate();
    setState(() {
      error = false;
      isLoading = false;
      jsonData = aggregate;
      pjsonData = jsonDecode(aggregate);
    });
  }

  Future<void> loadSelectedVote() async {
    final votedDate = await settings.getKey('votedDate');
    final wNearestWan = whenPlaneIntegration.getNearestWan();
    if (votedDate.isNotEmpty &&
        (wNearestWan['date'] as DateTime)
            .isAtSameMomentAs(DateTime.parse(votedDate))) {
      settings.getKey('votedname').then((value) {
        setState(() {
          selectedVote = value;
        });
      });
    } else {
      setState(() {
        selectedVote = null;
        settings.setKey(
            'votedDate', (nearestWan['date'] as DateTime).toIso8601String());
        settings.setKey('votedname', '');
      });
    }
  }

  dynamic platenessData;
  dynamic pjsonData;

  Map<String, dynamic> nearestWan = whenPlaneIntegration.getNearestWan();
  bool isMainLate = false;
  String countdownString = '';
  bool isAfterStartTime = false;
  DateTime nextWan = whenPlaneIntegration.getNextWAN(DateTime.now());
  String sscountdownText = '';
  bool isSSlate = false;
  bool showPlayed = false;

  bool error = false;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isLoading) return;
      if (pjsonData == null) return;

      if (pjsonData['specialStream'] != null &&
          pjsonData['specialStream'] is Map &&
          pjsonData['specialStream']['start'] != null) {
        final specialStreamStart =
            DateTime.parse(pjsonData['specialStream']['start']);
        if (mounted) {
          setState(() {
            isSSlate = DateTime.now().isAfter(specialStreamStart);
            final timeUntil =
                whenPlaneIntegration.getTimeUntil(specialStreamStart);
            sscountdownText = timeUntil['string'];
          });
        }
      }

      final isPreShow = pjsonData != null &&
          !(pjsonData['youtube']?['isLive'] ?? false) &&
          (pjsonData['twitch']?['isWAN'] ??
              false || pjsonData['floatplane']?['isWAN'] ??
              false);

      final isMainShow = pjsonData != null &&
          (pjsonData['youtube']?['isWAN'] ?? false) &&
          (pjsonData['youtube']?['isLive'] ?? false);

      if (isMainShow || isPreShow) {
        if (!isMainShow &&
            isPreShow &&
            pjsonData['twitch']?['isLive'] == true) {
          final mainScheduledStart =
              whenPlaneIntegration.getClosestWan(DateTime.now());
          if (mounted) {
            setState(() {
              isMainLate = true;
              final timeUntil =
                  whenPlaneIntegration.getTimeUntil(mainScheduledStart);
              countdownString = timeUntil['string'];
            });
          }
        } else if (mounted) {
          setState(() {
            isMainLate = false;
          });
        }

        // Use the first available started time from youtube, twitch, or floatplane
        final started = pjsonData['youtube']?['started'] ??
            pjsonData['twitch']?['started'] ??
            pjsonData['floatplane']?['started'];

        if (started != null) {
          try {
            final startedTime = DateTime.parse(started.toString());
            isAfterStartTime = true;
            showPlayed = true;
            final timeUntil = whenPlaneIntegration.getTimeUntil(startedTime);
            if (mounted) {
              setState(() {
                countdownString = timeUntil['string'];
              });
            }
          } catch (e) {
            debugPrint('Error parsing started time: $e');
          }
        }
      } else {
        if (showPlayed) {
          showPlayed = false;
          nextWan = whenPlaneIntegration.getNextWAN(DateTime.now(),
              hasDone: pjsonData['hasDone']);
        }

        final timeUntil = whenPlaneIntegration.getTimeUntil(nearestWan['date']);
        isAfterStartTime = timeUntil['late'];

        if (mounted) {
          setState(() {
            countdownString = timeUntil['string'];
            if (timeUntil['late']) {
              isMainLate = true;
            }
          });
        }
      }
    });

    _phraseTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) {
        setState(() {
          phrase = whenPlaneIntegration.newPhrase();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phraseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    k = generateK();
    final day = DateTime.now().toUtc().weekday;
    final dayIsCloseEnough = day == 5 || day == 6;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ageCutoff = 24 * 60 * 60e3;
    return error
        ? ErrorScreen(
            subtext: 'Floaty recieved an unexpected response.',
            image: 'assets/unexpected.png',
            message: jsonDecode(jsonData)['error'],
          )
        : isLoading
            ? Container(
                color: widget.v
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerLowest,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : LayoutBuilder(
                builder:
                    (BuildContext context, BoxConstraints viewportConstraints) {
                  return SingleChildScrollView(
                    child: Container(
                      width: double.infinity, // Ensure full width
                      constraints: BoxConstraints(
                        minHeight: viewportConstraints
                            .maxHeight, // Ensure it's at least as tall as the viewport
                      ),
                      color: widget.v
                          ? colorScheme.surface
                          : colorScheme.surfaceContainerLowest,
                      child: Column(
                        // Outer Column for centering the content block
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal:
                                    8.0), // Padding around the content block
                            child: Column(
                              // Inner Column for the actual content, sized to fit content
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (pjsonData['specialStream'] != false)
                                  _buildSpecialStreamCard(),
                                const SizedBox(height: 12.0),
                                _buildShowMightStartSoonAlert(
                                    colorScheme, textTheme),
                                const SizedBox(height: 12.0),
                                _buildCountdownCard(colorScheme, textTheme),
                                const SizedBox(height: 12.0),
                                _buildPlatformStatusContainer(),
                                const SizedBox(height: 12.0),
                                _buildLatenessStats(),
                                const SizedBox(height: 3.0),
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    launchUrl(
                                        Uri.parse('https://whenplane.com'));
                                  },
                                  child: Text('Data provided by Whenplane',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ),
                                const SizedBox(height: 12.0),
                                if (pjsonData['isThereWan']['text'] != null)
                                  _buildSpecialAlert(colorScheme),
                                const SizedBox(height: 12.0),
                                if (pjsonData != null &&
                                    !pjsonData['hasDone'] &&
                                    (DateTime.now().toUtc().weekday == 5 ||
                                        DateTime.now().toUtc().weekday == 6))
                                  ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: 600),
                                      child: _buildLatenessVoting(
                                          colorScheme, textTheme)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildSpecialStreamCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = 450.0;
        final width =
            constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;
        final height = width * 9 / 16;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              image: DecorationImage(
                image: NetworkImage(pjsonData['specialStream']['thumbnail']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.7),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Stream',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: width * 0.06,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pjsonData['specialStream']['title'],
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: width * 0.04,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPlatformIndicator(
                          'Floatplane',
                          pjsonData['specialStream']['onFloatplane'] == true,
                          width * 0.035,
                        ),
                        SizedBox(height: height * 0.01),
                        _buildPlatformIndicator(
                          'Twitch',
                          pjsonData['specialStream']['onTwitch'] == true,
                          width * 0.035,
                        ),
                        SizedBox(height: height * 0.01),
                        _buildPlatformIndicator(
                          'YouTube',
                          pjsonData['specialStream']['onYoutube'] == true,
                          width * 0.035,
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pjsonData['floatplane']['isLive']
                                      ? 'Currently Live'
                                      : isSSlate
                                          ? '$sscountdownText $phrase'
                                          : sscountdownText,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontSize: width * 0.045,
                                    color: pjsonData['floatplane']['isLive']
                                        ? colorScheme.primary
                                        : isSSlate
                                            ? colorScheme.error
                                            : colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            if (pjsonData['specialStream']
                                    ['startIsEstimated'] ==
                                true)
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('estimated'),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Tooltip(
                                        message:
                                            'Often, LTT does not announce streams, they just go live.\nSo the only way we know that a stream is happening is when they upload a title, description, and thumbnail.\nThis usually happens a few hours before the stream starts, and a guess is made at the start time.\nIt will be updated if there is any official word.',
                                        child: Icon(
                                          Icons.info_outline,
                                          size: width * 0.04,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
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

  Widget _buildPlatformIndicator(
      String platform, bool isAvailable, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$platform:',
          style: TextStyle(
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: 8.0),
        Icon(
          isAvailable ? Icons.check_circle : Icons.cancel,
          color: isAvailable ? Colors.green : Colors.red,
          size: fontSize + 2,
        ),
      ],
    );
  }

  Widget _buildCountdownCard(ColorScheme colorScheme, TextTheme textTheme) {
    bool isPreShow = pjsonData != null
        ? !(pjsonData['youtube']?['isLive'] ?? false) &&
            (pjsonData['twitch']?['isWAN'] ??
                false || (pjsonData['floatplane']?['isWAN'] ?? false))
        : false;

    bool isMainShow = pjsonData != null
        ? (pjsonData['youtube']?['isWAN'] ?? false) &&
            (pjsonData['youtube']?['isLive'] ?? false)
        : false;

    // bool preShowStarted = pjsonData['twitch']['started'] != null;

    bool mainShowStarted = pjsonData['youtube']['started'] != null;

    bool isLate =
        isAfterStartTime && !pjsonData['hasDone'] && !isPreShow && !isMainShow;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display text based on the state
            if (isLate)
              Text.rich(
                TextSpan(
                  text: 'The WAN show is currently',
                  style: textTheme.bodyLarge,
                  children: [
                    TextSpan(
                      text: ' ${isLate ? phrase : ''}',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' by'),
                  ],
                ),
                textAlign: TextAlign.center,
              )
            else if (isMainShow)
              Text(
                'The WAN show has been live for',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            else if (pjsonData['floatplane']['isLive'] != null &&
                pjsonData['floatplane']['isLive'] &&
                !(pjsonData['twitch']['isLive'] ?? false))
              Text(
                'The pre-pre-show has been live for',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            else if (isPreShow)
              Text(
                'The pre-show has been live for',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              )
            else
              Text(
                'The WAN show is (supposed) to start in',
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            Text(
              countdownString,
              style: textTheme.headlineMedium?.copyWith(
                color: isLate ? colorScheme.error : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isLate && !isMainShow) ...[
              Text(
                'Next WAN: ${DateFormat('MM/dd/yyyy HH:mm:ss').format(whenPlaneIntegration.getNextWAN(DateTime.now()).toLocal())}',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ] else if (isLate && !isMainShow) ...[
              Text(
                'It usually actually starts roughly 1 or 2 hours late.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ] else if ((isMainShow && mainShowStarted) || isPreShow) ...[
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: !isMainShow && pjsonData['floatplane']['isLive']
                          ? 'Pre-show started '
                          : (isPreShow &&
                                  !isMainShow &&
                                  pjsonData['floatplane']['isLive'] &&
                                  !pjsonData['twitch']['isLive'])
                              ? 'Pre-pre-show started '
                              : 'Started ',
                    ),
                    const TextSpan(text: 'at '),
                    if (mounted)
                      TextSpan(
                        text: (() {
                          final raw = pjsonData['youtube']['started'] ??
                              pjsonData['twitch']['started'] ??
                              pjsonData['floatplane']['started'];
                          final parsed = DateTime.tryParse(raw ?? '');
                          if (parsed == null) return 'unknown time';
                          final formatter = DateFormat('HH:mm:ss');
                          return formatter.format(parsed.toLocal());
                        })(),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformStatusContainer() {
    return Wrap(
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        _buildPlatformStatus(
          icon: SimpleIcons.twitch,
          platform: "Twitch",
          status: pjsonData['twitch']['isLive'] != null &&
                  pjsonData['twitch']['isLive']
              ? pjsonData['twitch']['isWAN'] != null &&
                      pjsonData['twitch']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['twitch']['isLive'] ?? false,
        ),
        _buildPlatformStatus(
          icon: SimpleIcons.youtube,
          isUpcoming: pjsonData['youtube']['upcoming'],
          platform: "Youtube",
          status: pjsonData['youtube']['isLive']
              ? pjsonData['youtube']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['youtube']['isLive'] ?? false,
        ),
        _buildPlatformStatus(
          icon: SimpleIcons.floatplane,
          isUpcoming: pjsonData['floatplane']['isThumbnailNew'] != null &&
              pjsonData['floatplane']['isThumbnailNew'],
          platform: "Floatplane",
          status: pjsonData['floatplane']['isLive'] != null &&
                  pjsonData['floatplane']['isLive']
              ? pjsonData['floatplane']['isWAN'] != null &&
                      pjsonData['floatplane']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : pjsonData['floatplane']['isThumbnailNew'] != null &&
                      pjsonData['floatplane']['isThumbnailNew']
                  ? '(upcoming ${pjsonData['floatplane']['isWAN'] != null ? (pjsonData['floatplane']['isWAN'] ? 'wan' : 'non-wan') : ''})'
                  : '(offline)',
          isLive: pjsonData['floatplane']['isLive'],
        ),
      ],
    );
  }

  Widget _buildPlatformStatus({
    required IconData icon,
    required String platform,
    required String status,
    required bool isLive,
    bool isUpcoming = false,
  }) {
    Color statusColor = isLive
        ? Colors.green
        : (isUpcoming ? Colors.yellow[700]! : Colors.grey);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Icon(icon, size: 45),
              ],
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  platform,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textScaleFactor: 1.0,
                  maxLines: 1,
                  minFontSize: 2.0,
                ),
                AutoSizeText(
                  isUpcoming ? '(upcoming)' : status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.0,
                  ),
                  minFontSize: 2.0,
                  textScaleFactor: 1.0,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatenessStats() {
    return Wrap(
      runSpacing: 8.0,
      children: [
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Average lateness',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  'from the last 5 shows',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${whenPlaneIntegration.timeString(
                    (platenessData['averageLateness'] as num).abs().toInt(),
                  )} $phrase',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        '± ${whenPlaneIntegration.timeString(
                          (platenessData['latenessStandardDeviation'] as num)
                              .abs()
                              .toInt(),
                        )}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Tooltip(
                      message:
                          '''Think of standard deviation as a measure that tells you how much individual values in a set typically differ from the average of that set. If the standard deviation is small, it means most values are close to the average. If it's large, it means values are more spread out from the average, indicating greater variability in the data. Essentially, standard deviation gives you an idea of how consistent or varied the values are in relation to the average.''',
                      child: Icon(Icons.info_outline, size: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Median lateness',
                  style: TextStyle(fontSize: 14),
                ),
                const Text(
                  'from the last 5 shows',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${whenPlaneIntegration.timeString(
                    (platenessData['medianLateness'] as num).abs().toInt(),
                  )} $phrase',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 17),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShowMightStartSoonAlert(
      ColorScheme colorScheme, TextTheme textTheme) {
    final isThumbnailNew = pjsonData['floatplane']?['isThumbnailNew'] ?? false;
    final thumbnailUrl = pjsonData['floatplane']?['thumbnail'] ?? '';
    final title = pjsonData['floatplane']?['title']?.split(' - ')[0] ?? '';
    final thumbnailAge = pjsonData['floatplane']?['thumbnailAge'] as int?;

    // Calculate the exact date and time when the thumbnail was updated
    final DateTime thumbnailUpdateTime = thumbnailAge != null
        ? DateTime.now()
            .subtract(Duration(milliseconds: thumbnailAge))
            .toLocal()
        : DateTime.now().toLocal();
    final String formattedTime =
        DateFormat('h:mm a').format(thumbnailUpdateTime);
    final String formattedDate =
        DateFormat('MMM d, y').format(thumbnailUpdateTime);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 154.5,
              height: 86.52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: colorScheme.surfaceContainerHighest,
                image: thumbnailUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(thumbnailUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: thumbnailUrl.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined,
                      size: 32, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            // Content
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isThumbnailNew)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'The show might start soon!',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  title.isNotEmpty ? '"$title"' : 'Untitled Stream',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThumbnailNew
                          ? 'The thumbnail was updated'
                          : 'The thumbnail was updated, but they haven\'t gone live yet.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (thumbnailAge != null)
                      Text(
                        'at $formattedTime on $formattedDate',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Info button
            Align(
              alignment: Alignment.centerRight,
              child: Tooltip(
                message:
                    'Generally when a thumbnail is uploaded, all hosts are in their seats ready to start the show.\nUsually the show starts within 10 minutes of a thumbnail being uploaded.',
                child: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  splashRadius: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialAlert(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.tertiaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Text(
            pjsonData['isThereWan']['text'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.0,
            ),
          ),
          if (pjsonData['isThereWan']['image'] != null)
            const SizedBox(height: 8.0),
          if (pjsonData['isThereWan']['image'] != null)
            Image.network(
              pjsonData['isThereWan']['image'],
              width: 400,
              fit: BoxFit.contain,
            ),
        ]),
      ),
    );
  }

  String generateK() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final base64 = base64Encode(utf8.encode(timestamp));
    return base64.replaceAll('=', '');
  }

  Widget _buildLatenessVoting(ColorScheme colorScheme, TextTheme textTheme) {
    // Calculate total votes
    int totalVotes = 0;
    for (var vote in pjsonData['votes']) {
      totalVotes += (vote['votes'] as int);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lateness Voting',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(votingrevealed
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
              onPressed: () => setState(() => votingrevealed = !votingrevealed),
            ),
          ],
        ),
        if (votingrevealed) ...[
          const SizedBox(height: 8.0),
          const Row(
            children: [
              Text('How late do you think the show will be?'),
              SizedBox(width: 4.0),
              Tooltip(
                message:
                    'Lateness voting starts every Friday at midnight UTC, and runs until the show starts.',
                child: Icon(Icons.info_outline, size: 16.0),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          ...pjsonData['votes'].map<Widget>((vote) {
            final voteCount = vote['votes'] as int;
            final voteName = vote['name'] as String;
            final isSelected = voteName == selectedVote;
            final percentage = totalVotes > 0
                ? (voteCount / totalVotes * 100).clamp(0, 100)
                : 0.0;

            final isExpired = DateTime.now().toUtc().isAfter(
                ((nearestWan['date'] as DateTime)
                    .toUtc()
                    .add(Duration(milliseconds: vote['time']))));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedVote = voteName;
                  whenPlaneIntegration.sendVote(voteName, generateK());
                  settings.setKey('votedname', voteName);
                }),
                child: Container(
                  height: 33,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        // Progress bar
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: percentage > 0
                                ? constraints.maxWidth * (percentage / 100)
                                : 0,
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? colorScheme.inversePrimary
                                  : colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Option content
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                // Radio button/checkmark
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: colorScheme.onPrimary,
                                          size: 12,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    voteName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isExpired
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.onSurface,
                                      decoration: isExpired
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                // Vote count
                                Text(
                                  '$voteCount Vote${voteCount != 1 ? 's' : ''}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Percentage
                                Text(
                                  '${percentage.round()}%',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
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
          }).toList(),
        ],
      ],
    );
  }
}
