import 'package:floaty/features/helpers/respositories/capitalize.dart';
import 'package:flutter/material.dart';
import 'package:floaty/features/updater/respositories/updater_controllers.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool isLoading = true;
  dynamic data;

  @override
  void initState() {
    super.initState();
    checkForUpdates();
  }

  Future<void> checkForUpdates() async {
    data = await updatercontroller.getUpdate();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data['deployment']['required'] == 1)
                      Text('Update Required',
                          style: theme.textTheme.titleLarge),
                    if (data['deployment']['required'] == 1)
                      SizedBox(height: 20),
                    Text('A new version of Floaty is available!',
                        style: theme.textTheme.bodyLarge),
                    Text(
                        '${capitalize(data['update']['flavor'])} version ${data['update']['version']}',
                        style: theme.textTheme.bodyLarge),
                    SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Image.network(
                              'https://floaty.fyi${data['update']['thumbnail']}')
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(data['update']['title'],
                        style: theme.textTheme.titleLarge),
                    SizedBox(height: 10),
                    Text(data['update']['summary'],
                        style: theme.textTheme.bodyLarge),
                    SizedBox(height: 10),
                    SizedBox(height: 10),
                    Text('Contributors: ${data['update']['content']}',
                        style: theme.textTheme.labelSmall),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: implement update
                        // updatercontroller.update();
                      },
                      child: Text('Update'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
