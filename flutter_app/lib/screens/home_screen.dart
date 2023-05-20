import 'package:flutter/material.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/utils/state_machines.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';

import '../controllers/home_controller.dart';
import '../routes/app_pages.dart';
import '../services/app_service.dart';
import '../utils/utils.dart';
import '../widgets/LoadingWidget.dart';
import '../widgets/SwipeDetector.dart';
import 'feedback_screen.dart';

class HomeScreen extends GetView<HomeController> {
  Set<int> dialogLock = {};

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //       appBar: AppBar(
  //         automaticallyImplyLeading: false,
  //         title: Text("home screen..."),
  //         actions: <Widget>[
  //           IconButton(
  //             icon: const Icon(Icons.settings),
  //             tooltip: 'Options',
  //             onPressed: () {
  //               Get.toNamed(Routes.OPTIONS);
  //             },
  //           ),
  //           IconButton(
  //             icon: const Icon(Icons.logout),
  //             tooltip: 'Logout',
  //             onPressed: () async {
  //               Get.find<AuthService>().signOut();
  //               Get.offAllNamed(Routes.LOGIN);
  //             },
  //           ),
  //         ],
  //       ),
  //       body: controller.obx(
  //         (state) => const Center(
  //           child: Text("this is the home..."),
  //         ),
  //         onLoading: const CircularProgressIndicator(),
  //         onEmpty: Column(
  //           children: const [
  //             Text('No Data found'),
  //           ],
  //         ),
  //       ));
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   controller controller = context.read<controller>();

  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     controller.socketMachine.current = SocketStates.connecting;
  //     controller.init(handleErrorCallback: handleError);
  //   });

  //   print("ChatScreenState initState");
  // }

  void showDialogAlert(int lockID, Widget title, Widget content) {
    // if (dialogLock.contains(lockID) == true) return;
    // if (lockID > 0) dialogLock.add(lockID);
    // func() => showDialog(
    //       context: context,
    //       builder: (BuildContext context) {
    //         return AlertDialog(
    //           title: title,
    //           content: content,
    //           actions: <Widget>[
    //             TextButton(
    //               child: const Text("OK"),
    //               onPressed: () {
    //                 dialogLock.remove(lockID);
    //                 Navigator.of(context).pop();
    //               },
    //             ),
    //           ],
    //         );
    //       },
    //     );
    // // Future.delayed(const Duration(seconds: 0), func);
    // Future.microtask(func);
  }

  void handleError(ErrorDetails details) {
    var content = IntrinsicHeight(
      child: Column(
        children: [
          Text(details.title),
          const Text(""),
          Text(
              style: const TextStyle(
                color: Colors.red,
              ),
              details.message),
        ],
      ),
    );
    showDialogAlert(
        details.message.hashCode, const Text("Socket Error"), content);
  }

  @override
  Widget build(BuildContext context) {
    isInChat() {
      return false;
    }

    isInReadyQueue() {
      return false;
    }

    // if (controller.chatMachine.current?.identifier ==
    //     ChatStates.feedback) {
    //   return FeedbackScreen(
    //       label: 'Submit Feedback', controller: controller, appProvider: null,);
    // }

    Widget chatButton = TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
              Colors.yellow.shade100), // Change the color here
        ),
        onPressed: () async {
          if (!isInReadyQueue()) {
            await controller.ready();
          } else {
            await controller.unReady();
          }
        },
        child: Text((isInReadyQueue() == false) ? 'Ready' : 'Cancel Ready'));

    Widget videoRenderLayout;

    BuildContext? context = Get.context;
    if (context != null ? context.isSmallTablet : false) {
      double ratioHW = 0;

      if (controller.localVideoRenderer.value.videoHeight != 0 &&
          controller.localVideoRenderer.value.videoWidth != 0) {
        ratioHW = controller.localVideoRenderer.value.videoHeight /
            controller.localVideoRenderer.value.videoWidth;
      }
      videoRenderLayout = Obx(() => Stack(
            children: [
              Container(
                color: Colors.black,
                child: RTCVideoView(
                  controller.remoteVideoRenderer.value,
                  // objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              Positioned(
                bottom: 20, // get the size of the row buttons..?
                right: 0,
                child: Container(
                  alignment: Alignment.bottomRight,
                  width: Get.width / 2,
                  height: (Get.width / 2) * ratioHW,
                  child: RTCVideoView(
                    controller.localVideoRenderer.value,
                  ),
                ),
              ),
            ],
          ));
    } else {
      videoRenderLayout = Obx(() => Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: RTCVideoView(controller.remoteVideoRenderer.value),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: RTCVideoView(controller.localVideoRenderer.value),
                ),
              ),
            ],
          ));
    }

    Widget chatButtons = Obx(
      () => controller.localMediaStream.value == null
          ? Container()
          : Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: "End call",
                    icon: const Icon(Icons.call_end),
                    color: isInChat() ? Colors.red : Colors.white,
                    onPressed: () {
                      if (isInChat()) {}
                    },
                  ),
                  IconButton(
                    tooltip: "Mute mic",
                    color: controller.isMuteMic() ? Colors.red : Colors.white,
                    icon: controller.isMuteMic()
                        ? const Icon(Icons.mic_off)
                        : const Icon(Icons.mic),
                    onPressed: () {
                      controller.toggleMuteMic();
                    },
                  ),
                  IconButton(
                    tooltip: "Camera off",
                    color: controller.isHideCam() ? Colors.red : Colors.white,
                    icon: controller.isHideCam()
                        ? const Icon(Icons.videocam_off)
                        : const Icon(Icons.videocam),
                    onPressed: () {
                      controller.toggleHideCam();
                    },
                  ),
                  // SettingsButton(controller),
                ],
              ),
            ),
    );

    videoRenderLayout = SwipeDetector(
        isDragUpdate: () {
          return isInChat();
        },
        onHorizontalDragEnd: (double score) {
          controller.sendChatScore(score).then((value) {}).catchError((error) {
            Get.snackbar(
              "Error",
              error.toString(),
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.withOpacity(.75),
              colorText: Colors.white,
              icon: const Icon(Icons.error, color: Colors.white),
              shouldIconPulse: true,
              barBlur: 20,
            );
          }).whenComplete(() {});
        },
        child: videoRenderLayout);

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Home"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Options',
              onPressed: () {
                Get.toNamed(Routes.OPTIONS);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                Get.find<AuthService>().signOut();
              },
            ),
          ],
        ),
        body: controller.obx(
          (state) => Flex(
            direction: Axis.horizontal,
            children: [
              isInChat() == false
                  ? Container(
                      width: 100,
                      color: Colors.white,
                      child: chatButton,
                    )
                  : Container(),
              Expanded(
                child: Stack(
                  children: [videoRenderLayout, chatButtons],
                ),
              ),
            ],
          ),
          onLoading: CircularProgressIndicator(),
          onError: (error) => Column(
            children: [
              Text("Socket Error"),
              Text('$error'),
              ElevatedButton(
                  onPressed: () {
                    controller.initSocket();
                  },
                  child: Text("Reconnect."))
            ],
          ),
        ));
  }
}

// class SettingsButton extends StatelessWidget {
//   const SettingsButton(this.controller, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<PopupMenuEntry<MediaDeviceInfo>>>(
//       future: controller.getDeviceEntries(),
//       builder: (context, snapshot) {
//         List<PopupMenuEntry<MediaDeviceInfo>> mediaList = [];

//         if (snapshot.hasData) {
//           mediaList = snapshot.data ?? [];
//         }

//         return PopupMenuButton<MediaDeviceInfo>(
//           color: Colors.white,
//           // initialValue: 'selectedMenu',
//           // Callback that sets the selected popup menu item.
//           itemBuilder: (BuildContext context) => mediaList,
//         );
//       },
//     );
//   }
// }
