import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:floaty/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/router/views/root_layout.dart';
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
            child: const SettingsListScreen(),
          ),
          const Divider(),
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
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
            onTap: () {
              context.go('/settings/account');
            },
          ),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/invoices',
            leading: Icon(Icons.receipt),
            title: Text('Invoices'),
            onTap: () {
              context.go('/settings/invoices');
            },
          ),
          Divider(),
          ListTile(
              title: Text('Floaty Settings',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            selected:
                GoRouterState.of(context).uri.path == '/settings/appearance',
            leading: Icon(Icons.brush),
            title: Text('Appearance'),
            onTap: () {
              context.go('/settings/appearance');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/player',
            leading: Icon(Icons.play_arrow),
            title: Text('Player'),
            onTap: () {
              context.go('/settings/player');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/updater',
            leading: Icon(Icons.update),
            title: Text('Updates'),
            onTap: () {
              context.go('/settings/updater');
            },
          ),
          ListTile(
            selected: GoRouterState.of(context).uri.path == '/settings/about',
            leading: Icon(Icons.info),
            title: Text('About'),
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
                    leading: Icon(Icons.developer_mode),
                    title: Text('Developer'),
                    onTap: () {
                      context.go('/settings/developer');
                    },
                  );
                }
                return const SizedBox.shrink();
              }),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final dir = await getApplicationSupportDirectory();
              final cookieJar = PersistCookieJar(
                storage: FileStorage('${dir.path}/.cookies/'),
              );
              await cookieJar.deleteAll();
              final hiveStore = HiveCacheStore('${dir.path}/.dio_cache');
              await hiveStore.clean();
              if (context.mounted) {
                context.go('/login');
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

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    final userinfo = await fpApiRequests.getUserInfo();
    setState(() {
      isLoading = false;
      user = userinfo;
    });
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
              title: const Text('Floatplane Account'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        foregroundImage: CachedNetworkImageProvider(
                          user?['selfUser']['profileImage']['path'] ?? '',
                        ),
                        backgroundImage: AssetImage('assets/placeholder.png'),
                      ),
                      SizedBox(height: 20),
                      AutoSizeText(user?['selfUser']['username'] ?? 'Unknown',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          textScaleFactor: 0.99,
                          minFontSize: 2),
                      SizedBox(height: 2),
                      AutoSizeText(user?['selfUser']['email'] ?? 'Unknown',
                          style: TextStyle(fontSize: 12),
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

  @override
  void initState() {
    super.initState();
    getdata();
  }

  void getdata() async {
    final invoices = await fpApiRequests.getInvoices();
    setState(() {
      isLoading = false;
      this.invoices = invoices;
    });
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
              title: const Text('Invoices'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop();
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
                      constraints: BoxConstraints(maxWidth: 600),
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
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Invoice ${invoice['id']}     ${DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date']))}',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: invoiceFontSize,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                'Amount: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountDue'])}        Subtotal: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountDue'])}        Taxes: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(invoice['amountTax'])}',
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
                                                                    'Amount: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountTotal'])}        Subtotal: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountSubtotal'])}        Taxes: ${NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(subscription['amountTax'])}',
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
                  context.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
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
      setState(() {
        packageInfo = info;
      });
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
                  context.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
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
                        now.difference(_lastTapTime!) > Duration(seconds: 2)) {
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
                SizedBox(height: 10),
                AutoSizeText(
                    'Floaty ${flavor.isNotEmpty ? flavor[0].toUpperCase() + flavor.substring(1) : ''}',
                    style: TextStyle(fontSize: 22),
                    maxLines: 2,
                    textScaleFactor: 0.99,
                    minFontSize: 2),
                SizedBox(height: 8),
                Text(
                  'v${packageInfo?.version ?? ''} (${packageInfo?.buildNumber ?? ''})',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      child: Padding(
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
                      child: Padding(
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
                      child: Padding(
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
                        //TODO: actual invite
                        launchUrl(
                            Uri.parse('https://discord.com/invite/floaty'));
                      },
                    ),
                  ],
                ),
                SizedBox(height: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    CustomCard(
                      name: 'bw86',
                      role: 'Developer',
                      avatarUrl:
                          'https://avatars.githubusercontent.com/u/51877146?v=4',
                      onTap: () {
                        launchUrl(Uri.parse('https://github.com/bw8686'));
                      },
                    ),
                  ],
                ),
                SizedBox(height: 15),
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
                SizedBox(height: 15),
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
  final VoidCallback onTap;

  const CustomCard({
    super.key,
    required this.name,
    this.role,
    this.avatarUrl,
    required this.onTap,
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
              title: Text('Player'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
              ),
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              ToggleSetting(
                title: 'Pause upon entering background',
                settingkey: 'pause_on_background',
              ),
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
                onPressed: () => Navigator.of(context).maybePop(),
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
                  RadioListTile<int>(
                    title: const Text('Classic Light'),
                    value: 0,
                    groupValue: themeType,
                    onChanged: (v) => settingsBox.put('theme_type', v!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Classic Dark'),
                    value: 1,
                    groupValue: themeType,
                    onChanged: (v) => settingsBox.put('theme_type', v!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Material You'),
                    value: 2,
                    groupValue: themeType,
                    onChanged: (v) => settingsBox.put('theme_type', v!),
                  ),
                  if (themeType == 2) ...[
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Material Color Source',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    RadioListTile<int>(
                      title: const Text('Device Dynamic Color'),
                      value: 0,
                      groupValue: src,
                      onChanged: (v) => settingsBox.put('material_source', v!),
                    ),
                    RadioListTile<int>(
                      title: const Text('Custom Color'),
                      value: 1,
                      groupValue: src,
                      onChanged: (v) => settingsBox.put('material_source', v!),
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
                    RadioListTile<int>(
                      title: const Text('Follow System'),
                      value: 0,
                      groupValue: dynamicMode,
                      onChanged: (v) {
                        settingsBox.put('material_dynamic_mode', v!);
                      },
                    ),
                    RadioListTile<int>(
                      title: const Text('Force Light'),
                      value: 1,
                      groupValue: dynamicMode,
                      onChanged: (v) =>
                          settingsBox.put('material_dynamic_mode', v!),
                    ),
                    RadioListTile<int>(
                      title: const Text('Force Dark'),
                      value: 2,
                      groupValue: dynamicMode,
                      onChanged: (v) =>
                          settingsBox.put('material_dynamic_mode', v!),
                    ),
                  ],
                  ToggleSetting(
                    title: 'Old UI components from old Floatplane design.',
                    settingkey: 'legacy_ui',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ToggleSetting extends StatefulWidget {
  const ToggleSetting({
    super.key,
    required this.title,
    required this.settingkey,
  });
  final String title;
  final String settingkey;
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
            value: newval ?? (snapshot.data ?? false),
            onChanged: (v) => {
              settings.toggleBool(widget.settingkey),
              setState(() {
                newval = v;
              }),
            },
          ),
        );
      },
    );
  }
}
