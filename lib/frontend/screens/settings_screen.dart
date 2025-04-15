import 'package:flutter/material.dart';
import 'package:floaty/frontend/root.dart';
import 'package:go_router/go_router.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cookie_jar/cookie_jar.dart';

// ignore: must_be_immutable
class SettingsScreen extends StatefulWidget {
  Widget child = const Text('Settings');
  SettingsScreen({super.key, required this.child});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            title: Text('Account Settings'),
            onTap: () {
              context.go('/settings/account');
            },
          ),
          ListTile(
            title: Text('Privacy Settings'),
            onTap: () {
              context.go('/settings/privacy');
            },
          ),
          Divider(),
          ListTile(
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

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
              title: const Text('Account Settings'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop();
                },
              ),
            )
          : null,
      body: const Center(
        child: Text('Account Settings'),
      ),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).size.width < 600
          ? AppBar(
              elevation: 0,
              toolbarHeight: 40,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              surfaceTintColor: Theme.of(context).appBarTheme.backgroundColor,
              title: const Text('Privacy Settings'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  context.pop();
                },
              ),
            )
          : null,
      body: Center(
        child: Text('Privacy Settings'),
      ),
    );
  }
}
