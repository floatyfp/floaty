import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:floaty/features/authentication/services/oauth2_service.dart';
import 'package:floaty/features/player/controllers/media_player_service.dart';
import 'package:floaty/app/flavor_theme.dart';
import 'package:floaty/shared/controllers/root_provider.dart';
import 'package:floaty/shared/utils/exceptions.dart';
import 'package:floaty/shared/views/error_screen.dart';
import 'package:floaty/whitelabels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/router/views/root_layout.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:floaty/features/api/repositories/fpapi.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:floaty/settings.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatefulWidget {
  final Widget child;
  const SettingsScreen({super.key, required this.child});
  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setapptitle();
    });
  }

  void setapptitle() {
    rootLayoutKey.currentState?.setAppBar(const Text('Settings'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 200,
            ),
            child: SettingsListScreen(),
          ),
          const VerticalDivider(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class SettingsListScreen extends StatelessWidget {
  const SettingsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
              title: Text('Floatplane Settings',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/account' ||
                    MediaQuery.of(context).size.width >= 600 &&
                        GoRouterState.of(context).uri.path == '/settings',
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () {
              context.go('/settings/account');
            },
          ),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/invoices',
            leading: const Icon(Icons.receipt),
            title: const Text('Invoices'),
            onTap: () {
              context.go('/settings/invoices');
            },
          ),
          const Divider(),
          const ListTile(
              title: Text('Floaty Settings',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/accounts',
            leading: const Icon(Icons.switch_account),
            title: const Text('Accounts'),
            onTap: () {
              context.go('/settings/accounts');
            },
          ),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/appearance',
            leading: const Icon(Icons.brush),
            title: const Text('Appearance'),
            onTap: () {
              context.go('/settings/appearance');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/player',
            leading: const Icon(Icons.play_arrow),
            title: const Text('Player'),
            onTap: () {
              context.go('/settings/player');
            },
          ),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/downloads',
            leading: const Icon(Icons.download),
            title: const Text('Downloads'),
            onTap: () {
              context.go('/settings/downloads');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/updater',
            leading: const Icon(Icons.update),
            title: const Text('Updates'),
            onTap: () {
              context.go('/settings/updater');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/about',
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              context.go('/settings/about');
            },
          ),
          FutureBuilder(
              future: Settings().getBool('developerMode'),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return ListTile(
                    selected: GoRouterState.of(context).uri.path ==
                        '/settings/developer',
                    leading: const Icon(Icons.developer_mode),
                    title: const Text('Developer'),
                    onTap: () {
                      context.go('/settings/developer');
                    },
                  );
                }
                return const SizedBox.shrink();
              }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              if (await whitelabels.getLoggedInLabelsLength() > 1) {
                final loggedLabels = await whitelabels.getLoggedInLabels();
                var selectedWhitelabel = 'all';
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Log out'),
                          content: RadioGroup(
                            groupValue: selectedWhitelabel,
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  selectedWhitelabel = value.toString();
                                }
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    'Select which account(s) you want to log out of.'),
                                ...loggedLabels
                                    .map((whitelabel) => RadioListTile(
                                          value: whitelabel.split('-')[0],
                                          title: Text(whitelabels
                                              .getWhitelabel(
                                                  whitelabel.split('-')[0])
                                              .name),
                                        )),
                                const RadioListTile(
                                  value: 'all',
                                  title: Text('Log out of all accounts'),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                context.pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Log out'),
                              onPressed: () async {
                                context.pop();
                                if (selectedWhitelabel == 'all') {
                                  final loggedLabels =
                                      await whitelabels.getLoggedInLabels();
                                  final labels =
                                      await whitelabels.getLabelsAndUsers();
                                  for (var label in loggedLabels) {
                                    final reallabel = labels.where((l) =>
                                        l.friendlyName == label.split('-')[0]);
                                    await OAuth2Service.instance
                                        .logout(reallabel.first);
                                  }
                                  if (context.mounted) {
                                    context.go('/login');
                                  }
                                } else {
                                  final whitelabel = whitelabels
                                      .getWhitelabel(selectedWhitelabel);
                                  final dir =
                                      await getApplicationSupportDirectory();
                                  final cookieJar = PersistCookieJar(
                                    storage:
                                        FileStorage('${dir.path}/.cookies/'),
                                  );
                                  await cookieJar.delete(Uri.parse(
                                    'https://www.${whitelabel.domain}',
                                  ));
                                  final hiveStore =
                                      HiveCacheStore('${dir.path}/.dio_cache ');
                                  await hiveStore.deleteFromPath(RegExp(
                                      'https://www.${whitelabel.domain}'));
                                  await fpApiRequests
                                      .logout(whitelabel.friendlyName);
                                  await whitelabels.removeLoggedInLabel(
                                      whitelabel.friendlyName);
                                  if ((await whitelabels
                                              .getFirstLoggedInLabelOrDefault())
                                          .friendlyName ==
                                      (await settings.getKey('whitelabel'))) {
                                    rootLayoutKey.currentState!.ref
                                        .read(
                                            mediaPlayerServiceProvider.notifier)
                                        .changeState(MediaPlayerState.none);
                                  }
                                  await settings.setKey(
                                      'whitelabel',
                                      (await whitelabels
                                              .getFirstLoggedInLabelOrDefault())
                                          .friendlyName);
                                  rootLayoutKey.currentState!.ref
                                      .read(rootProvider.notifier)
                                      .loadsidebar();
                                }
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                return;
              } else {
                final whitelabellist = await whitelabels.getLabelsAndUsers();
                final whitelabel = whitelabellist.firstWhere(
                  (label) => label.loggedin,
                  orElse: () => whitelabellist.first,
                );
                await OAuth2Service.instance.logout(whitelabel);
                await whitelabels.clearLoggedInLabels();
                if (context.mounted) {
                  context.go('/login');
                }
                return;
              }
            },
          )
        ],
      ),
    );
  }
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final Map<String, dynamic>? user;
  bool isLoading = true;
  FloatyException? _error;

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    setState(() {
      _error = null;
      isLoading = true;
    });

    try {
      final userinfo = await fpApiRequests.getUserInfo(
        (await whitelabels.getSelectedWhitelabel()).friendlyName,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          user = userinfo;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _error = NoInternetException(originalError: e);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = UnexpectedException(
            message: 'Failed to load profile',
            details: e.toString(),
            originalError: e,
          );
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Scaffold(
        appBar: MediaQuery.of(context).size.width < 600
            ? AppBar(
                elevation: 0,
                toolbarHeight: 40,
                backgroundColor: colorScheme.surfaceContainer,
                surfaceTintColor: colorScheme.surfaceContainer,
                title: const Text('Floatplane Account'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context.canPop() ? context.pop() : SystemNavigator.pop();
                  },
                ),
              )
            : null,
        body: ErrorScreen.fromException(
          _error!,
          onRetry: getdata,
        ),
      );
    }

    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Floatplane Account'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.canPop() ? context.pop() : SystemNavigator.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        foregroundImage: CachedNetworkImageProvider(
                          user?['profileImage']?['path'] ?? '',
                        ),
                        backgroundImage:
                            const AssetImage('assets/placeholder.png'),
                      ),
                      const SizedBox(height: 20),
                      AutoSizeText(user?['username'] ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          textScaleFactor: 0.99,
                          minFontSize: 2),
                      const SizedBox(height: 2),
                      AutoSizeText(user?['email'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          textScaleFactor: 0.99,
                          minFontSize: 2),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class InvoicesSettingsScreen extends StatefulWidget {
  const InvoicesSettingsScreen({super.key});
  @override
  State<InvoicesSettingsScreen> createState() => _InvoicesSettingsScreenState();
}

class _InvoicesSettingsScreenState extends State<InvoicesSettingsScreen> {
  late final Map<String, dynamic>? invoices;
  bool isLoading = true;
  FloatyException? _error;

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    setState(() {
      _error = null;
      isLoading = true;
    });

    try {
      final invoicesData = await fpApiRequests.getInvoices(
        (await whitelabels.getSelectedWhitelabel()).friendlyName,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
          invoices = invoicesData;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _error = NoInternetException(originalError: e);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = UnexpectedException(
            message: 'Failed to load invoices',
            details: e.toString(),
            originalError: e,
          );
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Scaffold(
        appBar: MediaQuery.of(context).size.width < 600
            ? AppBar(
                elevation: 0,
                toolbarHeight: 40,
                backgroundColor: colorScheme.surfaceContainer,
                surfaceTintColor: colorScheme.surfaceContainer,
                title: const Text('Invoices'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context.canPop() ? context.pop() : SystemNavigator.pop();
                  },
                ),
              )
            : null,
        body: ErrorScreen.fromException(
          _error!,
          onRetry: getdata,
        ),
      );
    }

    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Invoices'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.canPop() ? context.pop() : SystemNavigator.pop();
                },
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double cardPadding = 12;
          double cardSpacing = 8;
          double titleFontSize = 25;
          double iconSize = 24;
          double invoiceFontSize = 16;
          double subFontSize = 14;
          if (width > 900) {
            cardPadding = 24;
            cardSpacing = 18;
            titleFontSize = 32;
            iconSize = 32;
            invoiceFontSize = 18;
            subFontSize = 16;
          } else if (width > 600) {
            cardPadding = 16;
            cardSpacing = 12;
            titleFontSize = 28;
            iconSize = 28;
            invoiceFontSize = 17;
            subFontSize = 15;
          }
          return Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: cardSpacing),
                          Text(
                            'Invoices',
                            style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: cardSpacing),
                          if (invoices?['invoices'] == null ||
                              invoices!['invoices'].isEmpty)
                            const Text('No invoices found'),
                          if (invoices?['invoices'] != null &&
                              !invoices!['invoices'].isEmpty)
                            ...List<Widget>.from(
                              invoices!['invoices'].map(
                                (invoice) => Center(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(bottom: cardSpacing),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          invoice['paid']
                                              ? Icons.check_circle
                                              : Icons.close,
                                          size: iconSize,
                                          color: invoice['paid']
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Invoice ${invoice['id']}      ${DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date']))}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: invoiceFontSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                'Amount: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountDue'])}      Subtotal: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountDue'])}      Taxes: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountTax'])}',
                                                style: TextStyle(
                                                    fontSize: subFontSize),
                                              ),
                                              SizedBox(height: cardSpacing / 2),
                                              ...(invoice['subscriptions'] !=
                                                      null
                                                  ? List<Widget>.from(
                                                      (invoice['subscriptions']
                                                              as List)
                                                          .map<Widget>(
                                                        (subscription) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorScheme
                                                                .surfaceContainer,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            border:
                                                                Border.all(),
                                                          ),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      cardPadding,
                                                                  vertical:
                                                                      cardPadding /
                                                                          1.5),
                                                          margin: EdgeInsets.only(
                                                              bottom:
                                                                  cardSpacing /
                                                                      2),
                                                          child: Wrap(
                                                            crossAxisAlignment:
                                                                WrapCrossAlignment
                                                                    .center,
                                                            children: [
                                                              Padding(
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        right:
                                                                            cardPadding),
                                                                child:
                                                                    CircleAvatar(
                                                                  radius:
                                                                      iconSize *
                                                                          0.85,
                                                                  foregroundImage:
                                                                      CachedNetworkImageProvider(
                                                                    subscription['plan']['creator']
                                                                            [
                                                                            'icon']
                                                                        [
                                                                        'path'],
                                                                  ),
                                                                ),
                                                              ),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    '${subscription['plan']['creator']['title']} - ${subscription['plan']['title']}',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            subFontSize),
                                                                  ),
                                                                  Text(
                                                                    '${DateFormat('dd/MM/yyyy').format(DateTime.parse(subscription['periodStart']))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(subscription['periodEnd']))}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            subFontSize -
                                                                                1),
                                                                  ),
                                                                  Text(
                                                                    'Amount: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountTotal'])}      Subtotal: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountSubtotal'])}      Taxes: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountTax'])}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            subFontSize -
                                                                                1),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : []),
                                            ],
                                          ),
                                        ),
                                      ],
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
      ),
    );
  }
}

class LicensesSettingsScreen extends StatelessWidget {
  const LicensesSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Licenses'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.canPop() ? context.pop() : SystemNavigator.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FutureBuilder<List<LicenseEntry>>(
            future: _getAllLicenses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No licenses found.'));
              }
              final licenses = snapshot.data!;
              return ListView.builder(
                itemCount: licenses.length,
                itemBuilder: (context, index) {
                  final entry = licenses[index];
                  return ExpansionTile(
                    title: Text(entry.packages.join(', ')),
                    children: entry.paragraphs
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Text(p.text),
                            ))
                        .toList(),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<LicenseEntry>> _getAllLicenses() async {
    final List<LicenseEntry> all = [];
    await for (final entry in LicenseRegistry.licenses) {
      all.add(entry);
    }
    return all;
  }
}

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});
  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  DateTime? _lastTapTime;
  int _avatarTapCount = 0;
  PackageInfo? packageInfo;
  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          packageInfo = info;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const flavor =
        String.fromEnvironment('FLUTTER_FLAVOR', defaultValue: 'release');
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('About'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.canPop() ? context.pop() : SystemNavigator.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    if (_lastTapTime == null ||
                        now.difference(_lastTapTime!) >
                            const Duration(seconds: 2)) {
                      _avatarTapCount = 1;
                    } else {
                      _avatarTapCount += 1;
                    }
                    _lastTapTime = now;
                    if (_avatarTapCount >= 3) {
                      final res = await settings.toggleBool('developerMode');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Developer Mode ${res ? 'enabled' : 'disabled'}!')),
                        );
                      }
                      _avatarTapCount = 0; // Reset counter
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/${flavor}_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AutoSizeText(
                    'Floaty ${flavor.isNotEmpty ? flavor[0].toUpperCase() + flavor.substring(1) : ''}',
                    style: const TextStyle(fontSize: 22),
                    maxLines: 2,
                    textScaleFactor: 0.99,
                    minFontSize: 2),
                const SizedBox(height: 8),
                Text(
                  'v${packageInfo?.version ?? ''} (${packageInfo?.buildNumber ?? ''})',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                        child: Column(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.github,
                              size: 25,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'GitHub',
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        launchUrl(
                            Uri.parse('https://github.com/floatyfp/floaty'));
                      },
                    ),
                    TextButton(
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                        child: Column(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.globe,
                              size: 25,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Website',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        launchUrl(Uri.parse('https://floaty.fyi'));
                      },
                    ),
                    TextButton(
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 14),
                        child: Column(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.discord,
                              size: 25,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Discord',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        launchUrl(Uri.parse('https://floaty.fyi/discord'));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    CustomCard(
                      name: 'bw86',
                      role: 'Developer',
                      avatarUrl:
                          'https://avatars.githubusercontent.com/u/51877146?v=4',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Special thanks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    CustomCard(
                      name: 'ajgeiss0702',
                      role: 'Whenplane Owner',
                      avatarUrl:
                          'https://avatars.githubusercontent.com/u/6259574?v=4',
                      onTap: () {
                        launchUrl(Uri.parse('https://ajg0702.us/'));
                      },
                    ),
                    CustomCard(
                      name: 'EricApostal',
                      role: 'Cleaning my terrible code.',
                      avatarUrl:
                          'https://avatars.githubusercontent.com/u/60072374?v=4',
                      onTap: () {
                        launchUrl(Uri.parse('https://github.com/EricApostal/'));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                CustomCard(
                  name: 'Open source libraries',
                  onTap: () {
                    context.go('/settings/licenses');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String name;
  final String? role;
  final String? avatarUrl;
  final VoidCallback? onTap;
  const CustomCard({
    super.key,
    required this.name,
    this.role,
    this.avatarUrl,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (avatarUrl != null)
                SizedBox(
                  height: 45,
                  child: CircleAvatar(
                    radius: 22.5,
                    foregroundImage: NetworkImage(avatarUrl!),
                    backgroundColor: colorScheme.surface,
                  ),
                ),
              if (avatarUrl != null) const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (role != null) const SizedBox(height: 3),
                  if (role != null)
                    Text(
                      role!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({
    super.key,
  });
  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  bool? pauseOnBackground;
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Player'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              const ToggleSetting(
                title: 'Pause upon entering background',
                settingkey: 'pause_on_background',
              ),
              const ToggleSetting(
                title: 'Increment playback speed by 0.1x',
                settingkey: 'increment_playback_speed',
              ),
              if (!Platform.isAndroid && !Platform.isIOS)
                const ToggleSetting(
                  title: 'Discord RPC',
                  settingkey: 'discord_rpc',
                  defaultvalue: true,
                ),
              // if (Platform.isAndroid || Platform.isIOS)
              //   const PlayerTypeSelector(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({
    super.key,
  });
  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final box = Hive.box('settings');
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Appearance'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box settingsBox, _) {
              final themeType =
                  settingsBox.get('theme_type', defaultValue: 1) as int;
              final src =
                  settingsBox.get('material_source', defaultValue: 0) as int;
              final seed = settingsBox.get('material_seed_color',
                  defaultValue: (flavorPrimary?.toARGB32() ??
                      Colors.blue.toARGB32())) as int;
              final dynamicMode = settingsBox.get('material_dynamic_mode',
                  defaultValue: 0) as int;
              return ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Theme Mode',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  RadioGroup(
                    groupValue: themeType,
                    onChanged: (v) => settingsBox.put('theme_type', v!),
                    child: Column(
                      children: const [
                        RadioListTile<int>(
                          title: Text('Classic Light'),
                          value: 0,
                        ),
                        RadioListTile<int>(
                          title: Text('Classic Dark'),
                          value: 1,
                        ),
                        RadioListTile<int>(
                          title: Text('Material You'),
                          value: 2,
                        ),
                      ],
                    ),
                  ),
                  if (themeType == 2) ...[
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Material Color Source',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    RadioGroup(
                      groupValue: src,
                      onChanged: (v) => settingsBox.put('material_source', v!),
                      child: Column(
                        children: const [
                          RadioListTile<int>(
                            title: Text('Device Dynamic Color'),
                            value: 0,
                          ),
                          RadioListTile<int>(
                            title: Text('Custom Color'),
                            value: 1,
                          ),
                        ],
                      ),
                    ),
                    if (src == 1)
                      ListTile(
                        title: const Text('Pick Seed Color'),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(seed),
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        onTap: () async {
                          Color picker = Color(seed);
                          await showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Select Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: picker,
                                  onColorChanged: (c) => picker = c,
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    if (picker != Color(seed)) {
                                      settingsBox.put('material_seed_color',
                                          picker.toARGB32());
                                    }
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Material You Brightness',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    RadioGroup(
                      groupValue: dynamicMode,
                      onChanged: (v) {
                        settingsBox.put('material_dynamic_mode', v!);
                      },
                      child: Column(
                        children: const [
                          RadioListTile<int>(
                            title: Text('Follow System'),
                            value: 0,
                          ),
                          RadioListTile<int>(
                            title: Text('Force Light'),
                            value: 1,
                          ),
                          RadioListTile<int>(
                            title: Text('Force Dark'),
                            value: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const ToggleSetting(
                    title: 'Old UI components from old Floatplane design.',
                    settingkey: 'legacy_ui',
                  ),
                  //TODO: put back
                  // const ToggleSetting(
                  //   title: 'Bottom Navigation on small screens.',
                  //   settingkey: 'bottom_navigation',
                  //   defaultvalue: true,
                  // ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AccountsSettingsScreen extends StatefulWidget {
  const AccountsSettingsScreen({super.key});
  @override
  State<AccountsSettingsScreen> createState() => AccountsSettingsScreenState();
}

class AccountsSettingsScreenState extends State<AccountsSettingsScreen> {
  late final List<WhiteLabelWithUser> loggedInLabels;
  bool isLoading = true;
  FloatyException? _error;

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    setState(() {
      _error = null;
      isLoading = true;
    });

    try {
      final labels = await whitelabels.getLabelsAndUsers();
      if (mounted) {
        setState(() {
          loggedInLabels = labels;
          isLoading = false;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _error = NoInternetException(originalError: e);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = UnexpectedException(
            message: 'Failed to load accounts',
            details: e.toString(),
            originalError: e,
          );
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_error != null) {
      return Scaffold(
        appBar: MediaQuery.of(context).size.width < 600
            ? AppBar(
                elevation: 0,
                toolbarHeight: 40,
                backgroundColor: colorScheme.surfaceContainer,
                surfaceTintColor: colorScheme.surfaceContainer,
                title: const Text('Accounts'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              )
            : null,
        body: ErrorScreen.fromException(
          _error!,
          onRetry: getdata,
        ),
      );
    }

    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Accounts'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: loggedInLabels.length,
                      itemBuilder: (context, index) {
                        final whitelabel = loggedInLabels[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              whitelabel.whitelabel.logoPath,
                            ),
                          ),
                          title: Text(whitelabel.name),
                          subtitle: Text(whitelabel.loggedin
                              ? 'Logged In (${whitelabel.user!.username})'
                              : 'Not Logged In'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!whitelabel.loggedin)
                                IconButton(
                                  icon: const Icon(Icons.cookie),
                                  tooltip: 'Login with Cookie',
                                  onPressed: () async {
                                    final cookieController =
                                        TextEditingController();
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Cookie Login'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Paste your sails.sid cookie value:',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: cookieController,
                                              decoration: const InputDecoration(
                                                hintText: 's%3A...',
                                                border: OutlineInputBorder(),
                                              ),
                                              maxLines: 3,
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(dialogContext)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (cookieController
                                                  .text.isNotEmpty) {
                                                Navigator.of(dialogContext)
                                                    .pop(true);
                                              } else {
                                                ScaffoldMessenger.of(
                                                        dialogContext)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Please enter a cookie value')),
                                                );
                                              }
                                            },
                                            child: const Text('Login'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (result == true &&
                                        cookieController.text.isNotEmpty) {
                                      try {
                                        final dir =
                                            await getApplicationSupportDirectory();
                                        final cookieJar = PersistCookieJar(
                                          storage: FileStorage(
                                              '${dir.path}/.cookies/'),
                                        );

                                        final cookie = Cookie(
                                            'sails.sid', cookieController.text)
                                          ..domain =
                                              whitelabel.whitelabel.domain
                                          ..path = '/'
                                          ..httpOnly = true
                                          ..expires = DateTime.now()
                                              .add(const Duration(days: 365));

                                        // Save to both with and without www to ensure it works
                                        await cookieJar.saveFromResponse(
                                          Uri.parse(
                                              'https://www.${whitelabel.whitelabel.domain}'),
                                          [cookie],
                                        );
                                        await cookieJar.saveFromResponse(
                                          Uri.parse(
                                              'https://${whitelabel.whitelabel.domain}'),
                                          [cookie],
                                        );

                                        // Set auth method to cookie
                                        final oauth2Service =
                                            OAuth2Service.instance;
                                        await oauth2Service.setAuthMethod(
                                            'cookie',
                                            whitelabel: whitelabel
                                                .whitelabel.friendlyName);

                                        // Try to get user info to verify
                                        final userInfo = await fpApiRequests
                                            .getUserInfo(whitelabel
                                                .whitelabel.friendlyName);

                                        final userId =
                                            userInfo['id'] ?? 'cookie_user';
                                        await whitelabels.addLoggedInLabel(
                                            '${whitelabel.whitelabel.friendlyName}-$userId');

                                        if (context.mounted) {
                                          rootLayoutKey.currentState!.ref
                                              .read(rootProvider.notifier)
                                              .loadsidebar();
                                          final location =
                                              GoRouterState.of(context)
                                                  .uri
                                                  .toString();
                                          context.pushReplacement(
                                              '$location?time=${DateTime.now().millisecondsSinceEpoch}');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Login failed: $e')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (whitelabel.loggedin) {
                                    try {
                                      await OAuth2Service.instance.logout(
                                        whitelabel,
                                      );

                                      // Reload sidebar
                                      rootLayoutKey.currentState?.ref
                                          .read(rootProvider.notifier)
                                          .loadsidebar();

                                      // Refresh the page
                                      if (context.mounted) {
                                        final location =
                                            GoRouterState.of(context)
                                                .uri
                                                .toString();
                                        context.pushReplacement(
                                            '$location?time=${DateTime.now().millisecondsSinceEpoch}');
                                      }

                                      // If no accounts left, go to login
                                      if (context.mounted &&
                                          await whitelabels
                                                  .getLoggedInLabelsLength() ==
                                              0) {
                                        context.go('/login');
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Logout failed: $e')),
                                        );
                                      }
                                    }
                                  } else {
                                    // Login with OAuth2
                                    final oauth2Service =
                                        OAuth2Service.instance;
                                    final result = await oauth2Service.login(
                                      whiteLabel: whitelabel.whitelabel,
                                    );

                                    if (result.isSuccess) {
                                      await oauth2Service.storeTokens(
                                        result,
                                        whitelabel:
                                            whitelabel.whitelabel.friendlyName,
                                      );
                                      final userId = result.userInfo?['sub'] ??
                                          'oauth2_user';
                                      await whitelabels.addLoggedInLabel(
                                          '${whitelabel.whitelabel.friendlyName}-$userId');

                                      if (context.mounted) {
                                        rootLayoutKey.currentState!.ref
                                            .read(rootProvider.notifier)
                                            .loadsidebar();
                                        final location =
                                            GoRouterState.of(context)
                                                .uri
                                                .toString();
                                        context.pushReplacement(
                                            '$location?time=${DateTime.now().millisecondsSinceEpoch}');
                                      }
                                    }
                                  }
                                },
                                child: Text(
                                    whitelabel.loggedin ? 'Logout' : 'Login'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class DownloadsSettingsScreen extends StatefulWidget {
  const DownloadsSettingsScreen({super.key});

  @override
  State<DownloadsSettingsScreen> createState() =>
      _DownloadsSettingsScreenState();
}

class _DownloadsSettingsScreenState extends State<DownloadsSettingsScreen> {
  String? downloadPath;
  int downloadThreads = 3;
  String filenameTemplate = '%title% (%quality%)';
  bool creatorFolder = true;
  bool channelFolder = false;
  bool overwriteDownload = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var path = await settings.getDynamic('download_path');
    // Use downloads directory as default if no custom path set
    if (path == null) {
      try {
        final downloadsDir = await getDownloadsDirectory();
        path = downloadsDir?.path;
      } catch (e) {
        // Fallback to app directory if downloads directory not available
        final appDir = await getApplicationDocumentsDirectory();
        path = appDir.path;
      }
    }
    final threads =
        await settings.getDynamic('download_threads', defaultValue: 3);
    final template = await settings.getDynamic('download_filename',
        defaultValue: '%title% (%quality%)');
    final creator =
        await settings.getBool('creator_folder', defaultValue: true);
    final channel = await settings.getBool('channel_folder');
    final overwrite = await settings.getBool('overwrite_download');

    if (mounted) {
      setState(() {
        downloadPath = path;
        downloadThreads = threads;
        filenameTemplate = template;
        creatorFolder = creator;
        channelFolder = channel;
        overwriteDownload = overwrite;
      });
    }
  }

  Future<void> _pickDownloadPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await settings.setDynamic('download_path', result);
      setState(() {
        downloadPath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: colorScheme.surfaceContainer,
              surfaceTintColor: colorScheme.surfaceContainer,
              title: const Text('Downloads'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              ListTile(
                title: const Text('Download Location'),
                subtitle: Text(
                  downloadPath ?? 'Default (App Directory)',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickDownloadPath,
                  tooltip: 'Choose folder',
                ),
              ),
              ListTile(
                title: const Text('Concurrent Downloads'),
                subtitle: Text('$downloadThreads downloads at once'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: downloadThreads.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: downloadThreads.toString(),
                    onChanged: (value) async {
                      final newValue = value.toInt();
                      await settings.setDynamic('download_threads', newValue);
                      setState(() {
                        downloadThreads = newValue;
                      });
                    },
                  ),
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'File Organization',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                title: const Text('Filename Template'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filenameTemplate,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: %creator%, %channel%, %title%, %quality%',
                      style: TextStyle(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => _FilenameTemplateDialog(
                        initialValue: filenameTemplate,
                      ),
                    );
                    if (result != null) {
                      await settings.setDynamic('download_filename', result);
                      setState(() {
                        filenameTemplate = result;
                      });
                    }
                  },
                ),
              ),
              const ToggleSetting(
                title: 'Organize by Creator',
                settingkey: 'creator_folder',
                defaultvalue: true,
              ),
              const ToggleSetting(
                title: 'Organize by Channel',
                settingkey: 'channel_folder',
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Advanced',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const ToggleSetting(
                title: 'Overwrite Existing Files',
                settingkey: 'overwrite_download',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilenameTemplateDialog extends StatefulWidget {
  final String initialValue;

  const _FilenameTemplateDialog({required this.initialValue});

  @override
  State<_FilenameTemplateDialog> createState() =>
      _FilenameTemplateDialogState();
}

class _FilenameTemplateDialogState extends State<_FilenameTemplateDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filename Template'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Template',
              hintText: '%title% (%quality%)',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Available variables:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text('%creator% - Creator name',
              style: TextStyle(fontSize: 12)),
          const Text('%channel% - Channel name',
              style: TextStyle(fontSize: 12)),
          const Text('%title% - Video title', style: TextStyle(fontSize: 12)),
          const Text('%quality% - Quality (e.g., 1080p)',
              style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ToggleSetting extends StatefulWidget {
  const ToggleSetting({
    super.key,
    required this.title,
    required this.settingkey,
    this.defaultvalue,
  });
  final String title;
  final String settingkey;
  final bool? defaultvalue;
  @override
  State<ToggleSetting> createState() => _ToggleSettingState();
}

class _ToggleSettingState extends State<ToggleSetting> {
  bool? newval;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: settings.getBool(widget.settingkey),
      builder: (context, snapshot) {
        return ListTile(
          title: Text(widget.title),
          trailing: Switch(
            value: newval ?? (snapshot.data ?? widget.defaultvalue ?? false),
            onChanged: (v) {
              settings.toggleBool(widget.settingkey);
              setState(() {
                newval = v;
              });
            },
          ),
        );
      },
    );
  }
}

// class PlayerTypeSelector extends StatefulWidget {
//   const PlayerTypeSelector({super.key});
//   @override
//   State<PlayerTypeSelector> createState() => _PlayerTypeSelectorState();
// }

// class _PlayerTypeSelectorState extends State<PlayerTypeSelector> {
//   PlayerType? selectedVODPlayerType;
//   PlayerType? selectedLivePlayerType;
//   @override
//   void initState() {
//     super.initState();
//     _loadPlayerType();
//   }

//   Future<void> _loadPlayerType() async {
//     final playerVODTypeString = await Settings().getKey('player_backend');
//     PlayerType playerVODType;
//     if (playerVODTypeString.isEmpty) {
//       // Use default based on platform
//       playerVODType = Platform.isAndroid || Platform.isIOS
//           ? PlayerType.betterPlayer
//           : PlayerType.mediaKit;
//     } else {
//       // Convert string to enum
//       playerVODType = PlayerType.values.firstWhere(
//         (e) => e.toString() == 'PlayerType.$playerVODTypeString',
//         orElse: () => Platform.isAndroid || Platform.isIOS
//             ? PlayerType.betterPlayer
//             : PlayerType.mediaKit,
//       );
//     }
//     setState(() {
//       selectedVODPlayerType = playerVODType;
//     });
//   }

//   Future<void> _setPlayerType(PlayerType? type) async {
//     if (type == null) return;
//     final enumString = type.toString().split('.').last;
//     await Settings().setKey('player_backend', enumString);
//     setState(() {
//       selectedVODPlayerType = type;
//     });
//     await MediaPlayerService().loadPlayer(type);
//   }

//   String _getPlayerTypeName(PlayerType type) {
//     switch (type) {
//       case PlayerType.mediaKit:
//         return 'Media Kit';
//       case PlayerType.betterPlayer:
//         return 'Better Player';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (selectedVODPlayerType == null) {
//       return const SizedBox.shrink();
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         RadioGroup(
//           groupValue: selectedVODPlayerType,
//           onChanged: _setPlayerType,
//           child: Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(8),
//                 child: Text(
//                   'Player Backend',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               RadioListTile<PlayerType>(
//                 title: Text(_getPlayerTypeName(PlayerType.mediaKit)),
//                 value: PlayerType.mediaKit,
//               ),
//               RadioListTile<PlayerType>(
//                 title: Text(_getPlayerTypeName(PlayerType.betterPlayer)),
//                 value: PlayerType.betterPlayer,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
