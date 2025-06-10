import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:floaty/features/whenplane/repositories/whenplaneintergration.dart';
import 'package:floaty/settings.dart';
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

    // Calculate total votes
    totalVotes = votes.fold(0, (sum, vote) => sum + (vote['votes'] as int));
  }

  void initFetch() async {
    jsonData = await whenPlaneIntegration.aggregate();
    latenessData = await whenPlaneIntegration.lateness();
    setState(() {
      isLoading = false;
      isAfterStartTime = nearestWan['isNext']
          ? nearestWan['timeUntil'] > Duration.zero
          : nearestWan['timeUntil'] < Duration.zero;
    });
  }

  void websocketStart() async {
    final stream = whenPlaneIntegration.streamWebsocket();
    stream.listen((message) {
      if (message != 'pong') {
        if (mounted) {
          setState(() {
            jsonData = message;
          });
        }
      }
    });
  }

  Future<void> loadSelectedVote() async {
    settings.getKey('votedname').then((value) {
      setState(() {
        selectedVote = value;
      });
    });
  }

  late dynamic platenessData;
  late dynamic pjsonData;

  Map<String, dynamic> nearestWan = whenPlaneIntegration.getNearestWan();
  bool isMainLate = false;
  String countdownString = '';
  bool isAfterStartTime = false;
  DateTime nextWan = whenPlaneIntegration.getNextWAN(DateTime.now());
  String sscountdownText = '';
  bool isSSlate = false;
  bool showPlayed = false;
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isLoading) return;
      bool isPreShow = pjsonData != null
          ? !(pjsonData['youtube']?['isLive'] ?? false) &&
              (pjsonData['twitch']?['isWAN'] ??
                  false || (pjsonData['floatplane']?['isWAN'] ?? false))
          : false;

      bool isMainShow = pjsonData != null
          ? (pjsonData['youtube']?['isWAN'] ?? false) &&
              (pjsonData['youtube']?['isLive'] ?? false)
          : false;
      if (pjsonData['specialStream'] != false &&
          pjsonData['specialStream'] != null) {
        final timeUntil = whenPlaneIntegration
            .getTimeUntil(DateTime.parse(pjsonData['specialStream']?['start']));

        sscountdownText = timeUntil['string'];
        isSSlate = timeUntil['late'];
      }
      if (isMainShow || isPreShow) {
        if (!isMainShow && isPreShow && pjsonData['floatplane']?['isLive']) {
          final mainScheduledStart =
              whenPlaneIntegration.getClosestWan(DateTime.now());
          setState(() {
            isMainLate = true;
            countdownString =
                whenPlaneIntegration.getTimeUntil(mainScheduledStart)['string'];
          });
        } else {
          setState(() {
            isMainLate = false;
          });
        }

        DateTime started = DateTime.parse(pjsonData['floatplane']?['started'] ??
            pjsonData['youtube']?['started'] ??
            '');

        isAfterStartTime = true;
        showPlayed = true;
        countdownString = whenPlaneIntegration.getTimeUntil(started)['string'];
      } else {
        if (showPlayed) {
          showPlayed = false;
          nextWan = whenPlaneIntegration.getNextWAN(DateTime.now(),
              hasDone: pjsonData['hasDone']);
        }

        final timeUntil = whenPlaneIntegration.getTimeUntil(nextWan);
        countdownString = timeUntil['string'];
        isAfterStartTime = timeUntil['late'];

        if (timeUntil['late']) {
          setState(() {
            isMainLate = true;
            countdownString = timeUntil['string'];
          });
        }
      }
      if (mounted) {
        setState(() {});
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      pjsonData = jsonDecode(jsonData);
      platenessData = jsonDecode(latenessData);
    }
    k = generateK();
    final day = DateTime.now().toUtc().weekday;
    final dayIsCloseEnough = day == 5 || day == 6;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    _startTimer();
    return isLoading
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
                            if (!pjsonData['floatplane']?['isLive'] &&
                                pjsonData['floatplane']?['isWAN'] == bool &&
                                pjsonData['floatplane']?['isWAN'] &&
                                ((dayIsCloseEnough &&
                                        (pjsonData['floatplane']
                                                        ?['isThumbnailNew'] !=
                                                    null &&
                                                pjsonData['floatplane']
                                                    ?['isThumbnailNew'] ||
                                            pjsonData['floatplane']
                                                        ?['thumbnailAge'] !=
                                                    null &&
                                                pjsonData['floatplane']
                                                        ?['thumbnailAge'] <
                                                    24 * 60 * 60e3)) &&
                                    !pjsonData['hasDone']))
                              _buildShowMightStartSoonAlert(colorScheme),
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
                                launchUrl(Uri.parse('https://whenplane.com'));
                              },
                              child: Text('Data provided by Whenplane',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ),
                            const SizedBox(height: 12.0),
                            if (pjsonData['isThereWan']['text'] != null)
                              _buildSpecialAlert(colorScheme),
                            const SizedBox(height: 12.0),
                            if (pjsonData['isDone'] == false &&
                                (DateTime.now().toUtc().weekday == 5 ||
                                    DateTime.now().toUtc().weekday == 6))
                              ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 600),
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
                            if (pjsonData['specialStream']['isEstimated'] ==
                                true)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Tooltip(
                                  message: 'Estimated start time',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: width * 0.04,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
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

    bool isLate = isAfterStartTime && !isPreShow && !isMainShow;

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
              AutoSizeText.rich(
                TextSpan(
                  text: 'The WAN show is currently',
                  style: TextStyle(fontSize: 16.0),
                  children: [
                    TextSpan(
                      text: ' late',
                      style: TextStyle(fontSize: 16.0, color: Colors.red),
                    ),
                    TextSpan(
                      text: ' by',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              )
            else if (isMainShow)
              AutoSizeText(
                'The WAN show has been live for',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
                maxLines: 2,
              )
            else if (pjsonData['floatplane']['isLive'] != null &&
                pjsonData['floatplane']['isLive'] &&
                pjsonData['floatplane']['isWAN'] &&
                !pjsonData['twitch']['isLive'])
              AutoSizeText(
                'The pre-pre-show has been live for',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
                maxLines: 2,
              )
            else if (isPreShow)
              AutoSizeText(
                'The pre-show has been live for',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
                maxLines: 2,
              )
            else
              AutoSizeText(
                'The WAN show is (supposed) to start in',
                style: TextStyle(fontSize: 16.0),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            AutoSizeText(
              '$countdownString ${isLate ? phrase : ''}',
              minFontSize: 16.0,
              style: textTheme.headlineMedium?.copyWith(
                color: isLate ? colorScheme.error : colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              textScaleFactor: 1,
              maxLines: 1,
            ),

            if (!isAfterStartTime && !isMainShow) ...[
              AutoSizeText(
                'Next WAN: ${DateFormat('MM/dd/yyyy HH:mm:ss').format(whenPlaneIntegration.getNextWAN(DateTime.now()).toLocal())}',
                minFontSize: 8.0,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ] else if (isLate) ...[
              const AutoSizeText(
                  'It usually actually starts between 1 and 3 hours late.',
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ] else if ((isMainShow && mainShowStarted) || isPreShow) ...[
              AutoSizeText.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  children: [
                    TextSpan(
                      text: isPreShow
                          ? 'Pre-show started '
                          : (pjsonData['floatplane']['isLive'] &&
                                  pjsonData['floatplane']['isWAN'] &&
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
                        style: const TextStyle(fontSize: 16.0),
                      ),
                  ],
                ),
                maxLines: 1,
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
          status: pjsonData['twitch']['isLive']
              ? pjsonData['twitch']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
              : '(offline)',
          isLive: pjsonData['twitch']['isLive'],
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
          isLive: pjsonData['youtube']['isLive'],
        ),
        _buildPlatformStatus(
          icon: SimpleIcons.floatplane,
          platform: "Floatplane",
          status: pjsonData['floatplane']['isLive']
              ? pjsonData['floatplane']['isWAN']
                  ? '(live)'
                  : '(live non-WAN)'
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

  Widget _buildShowMightStartSoonAlert(ColorScheme colorScheme) {
    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.primaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 8.0,
          direction: Axis.horizontal,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 175,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    image: DecorationImage(
                      image: NetworkImage(
                        pjsonData['floatplane']['thumbnail'],
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pjsonData['floatplane']?['isThumbnailNew'])
                  AutoSizeText(
                    maxLines: 1,
                    'The show might start soon!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                AutoSizeText(
                  '"${pjsonData['floatplane']['title'].split(' - ')[0]}"',
                  maxLines: 2,
                  style: TextStyle(fontSize: 20),
                  overflow: TextOverflow.ellipsis,
                ),
                AutoSizeText.rich(
                  maxLines: 2,
                  TextSpan(
                    text: 'The thumbnail was updated',
                    children: [
                      TextSpan(
                        text: pjsonData['floatplane']?['isThumbnailNew']
                            ? ""
                            : ",",
                      ),
                      TextSpan(
                        text: pjsonData['floatplane']?['isThumbnailNew']
                            ? ""
                            : " but they haven't gone live yet.",
                      ),
                    ],
                  ),
                ),
                AutoSizeText.rich(
                  maxLines: 2,
                  TextSpan(
                    text: pjsonData['floatplane']?['isThumbnailNew']
                        ? ""
                        : "It was updated",
                    children: [
                      TextSpan(
                        text:
                            ' ${whenPlaneIntegration.timeString(pjsonData['floatplane']?['thumbnailAge'], long: true, showSeconds: false)}ago',
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message:
                      'Generally when a thumbnail is uploaded, all hosts are in their seats ready to start the show.\nUsually the show starts within 10 minutes of a thumbnail being uploaded.',
                  child: Icon(Icons.info_outline, size: 16),
                ),
              ],
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
          //  color: ((whenPlaneIntegration.getTimeUntil(
          //                                                   whenPlaneIntegration
          //                                                           .getNearestWan(
          //                                                               DateTime.now())[
          //                                                       'date'] as DateTime,
          //                                                   now: DateTime
          //                                                       .now())['distance'] ??
          //                                               0)
          //                                           .abs()) >
          //                                       (vote['time'] as int?) ??
          //                                   0
          //                               ? Colors.grey
          //                               : Colors.white,
          //                           decoration: ((whenPlaneIntegration.getTimeUntil(
          //                                                   whenPlaneIntegration
          //                                                           .getNearestWan(
          //                                                               DateTime.now())[
          //                                                       'date'] as DateTime,
          //                                                   now: DateTime
          //                                                       .now())['distance'] ??
          //                                               0)
          //                                           .abs()) >
          //                                       (vote['time'] as int?) ??
          //                                   0
          //                               ? TextDecoration.lineThrough
          //                               : null,
          //                         ),
          //                       ),
          //                       Text(percentageText),
          //                     ],
          //                   ),
          //                   const SizedBox(height: 4.0),
          //                   Container(
          //                     decoration: BoxDecoration(
          //                       borderRadius: BorderRadius.circular(4.0),
          //                     ),
          //                     clipBehavior: Clip.antiAlias,
          //                     child: LinearProgressIndicator(
          //                       value: percentage > 0 ? percentage / 100 : 0,
          //                       backgroundColor: Colors.grey[700],
          //                       color: ((whenPlaneIntegration.getTimeUntil(
          //                                                   whenPlaneIntegration
          //                                                           .getNearestWan(
          //                                                               DateTime.now())[
          //                                                       'date'] as DateTime,
          //                                                   now: DateTime.now())[
          //                                               'distance'] ??
          //                                           0)
          //                                       .abs()) >
          //                                   (vote['time'] as int?) ??
          //                               0
          //                           ? Colors.grey[800]
          //                           : Theme.of(context).colorScheme.primary,
          ...pjsonData['votes'].map<Widget>((vote) {
            final voteCount = vote['votes'] as int;
            final voteName = vote['name'] as String;
            final isSelected = voteName == selectedVote;
            final percentage = totalVotes > 0
                ? (voteCount / totalVotes * 100).clamp(0, 100)
                : 0.0;

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
                          child: Container(
                            width: percentage > 0
                                ? constraints.maxWidth * (percentage / 100)
                                : 0,
                            decoration: BoxDecoration(
                              color: ((whenPlaneIntegration.getTimeUntil(
                                                      whenPlaneIntegration
                                                              .getNearestWan(
                                                                  DateTime
                                                                      .now())[
                                                          'date'] as DateTime,
                                                      now: DateTime
                                                          .now())['distance'] ??
                                                  0)
                                              .abs()) >
                                          (vote['time'] as int?) ??
                                      0
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
                                // Option name
                                // color: ((whenPlaneIntegration.getTimeUntil(
                                //                                                   whenPlaneIntegration
                                //                                                           .getNearestWan(
                                //                                                               DateTime.now())[
                                //                                                       'date'] as DateTime,
                                //                                                   now: DateTime
                                //                                                       .now())['distance'] ??
                                //                                               0)
                                //                                           .abs()) >
                                //                                       (vote['time'] as int?) ??
                                //                                   0
                                //                               ? Colors.grey
                                //                               : Colors.white,
                                //                           decoration: ((whenPlaneIntegration.getTimeUntil(
                                //                                                   whenPlaneIntegration
                                //                                                           .getNearestWan(
                                //                                                               DateTime.now())[
                                //                                                       'date'] as DateTime,
                                //                                                   now: DateTime
                                //                                                       .now())['distance'] ??
                                //                                               0)
                                //                                           .abs()) >
                                //                                       (vote['time'] as int?) ??
                                //                                   0
                                //                               ? TextDecoration.lineThrough
                                //                               : null,
                                Expanded(
                                  child: Text(
                                    voteName,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: ((whenPlaneIntegration.getTimeUntil(
                                                              whenPlaneIntegration
                                                                      .getNearestWan(
                                                                          DateTime
                                                                              .now())['date']
                                                                  as DateTime,
                                                              now: DateTime
                                                                  .now())['distance'] ??
                                                          0)
                                                      .abs()) >
                                                  (vote['time'] as int?) ??
                                              0
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.onSurface,
                                      decoration: ((whenPlaneIntegration.getTimeUntil(
                                                              whenPlaneIntegration
                                                                      .getNearestWan(
                                                                          DateTime
                                                                              .now())['date']
                                                                  as DateTime,
                                                              now: DateTime
                                                                  .now())['distance'] ??
                                                          0)
                                                      .abs()) >
                                                  (vote['time'] as int?) ??
                                              0
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
