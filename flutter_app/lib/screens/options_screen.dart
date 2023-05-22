// Dart imports:

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Project imports:
import '../controllers/options_controller.dart';
import '../services/local_preferences_service.dart';
import '../widgets/left_nav_widget.dart';
import '../widgets/loadging_widgets.dart';

class OptionsScreen extends GetView<PreferencesController> {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget profile = Obx(() {
      return Container(
          alignment: Alignment.topCenter,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(
            maxWidth: 1000,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 35.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Divider(),
              UserProfileWidget(
                priority: controller.priority(),
              ),
            ],
          ));
    });

    LocalPreferences localPreferences = Get.find();

    Widget preferences = controller.obx(
      (state) => Obx(() => Column(children: [
            Row(
              children: [
                const Text("Swipe:"),
                Switch(
                  value: localPreferences.swipeFeedback(),
                  onChanged: (bool newValue) async {
                    localPreferences.swipeFeedback(newValue);
                  },
                )
              ],
            ),
            Row(
              children: [
                const Text("Swipe popup:"),
                Switch(
                  value: localPreferences.feedbackPopup(),
                  onChanged: (bool newValue) async {
                    localPreferences.feedbackPopup(newValue);
                  },
                )
              ],
            ),
            Row(
              children: [
                const Text("Auto queue:"),
                Switch(
                  value: localPreferences.autoQueue(),
                  onChanged: (bool newValue) async {
                    localPreferences.autoQueue(newValue);
                  },
                )
              ],
            )
          ])),
      onLoading: const CircularProgressIndicator(),
      onError: (error) => Column(
        children: [
          const Text("Options Error."),
          Text('$error'),
        ],
      ),
    );

    Widget settings = Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Colors.teal,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 1000,
        ),
        child: false
            ? connectingWidget
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 35.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Divider(),
                  preferences,
                  const Divider(),
                  // devices
                ],
              ));

    return WillPopScope(
        onWillPop: () async {
          if (!controller.unsavedChanges()) return true;

          bool confirm = await Get.dialog(AlertDialog(
            title: const Text('You have unsaved changes.'),
            content: const Text('Do you want to discard your changes?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Discard'),
              ),
            ],
          ));
          return confirm;
        },
        child: LeftNav(
            title: 'Options',
            body: Center(
                child: SingleChildScrollView(
                    child: Column(
              children: [profile, settings, const AppDetailsWidget()],
            )))));
  }
}

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key, required this.priority});

  final double priority;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Text("Failed to load user.");

    String? displayName = user.displayName;
    String? email = user.email;

    return Column(
      children: [
        user.isAnonymous
            ? Row(
                children: const [Text("This user is Anonymous.")],
              )
            : Column(children: [
                Row(
                  children: [
                    const Text("Display Name: "),
                    Text(displayName ?? "No display name")
                  ],
                ),
                Row(
                  children: [const Text("Email: "), Text(email ?? "No email")],
                ),
              ]),
        Row(
          children: [const Text("Priority: "), Text("$priority")],
        )
      ],
    );
  }
}

class AppDetailsWidget extends StatelessWidget {
  const AppDetailsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String version = "None";

          if (snapshot.hasData && snapshot.data?.version != null) {
            version = snapshot.data?.version ?? "None";
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ListTile(
                title: const Text("Version", textAlign: TextAlign.center),
                subtitle: Text(version, textAlign: TextAlign.center),
              ),
            ],
          );
        });
  }
}
