// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:flutter_app/services/auth_service.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_event_model.dart';
import '../models/chat_room_model.dart';

class ChatRoom extends GetView<ChatController> {
  final ChatRoomModel chatroom;

  const ChatRoom(this.chatroom, {super.key});

  @override
  Widget build(BuildContext context) {
    RxList<ChatEventModel> chatList = controller.loadChat(chatroom.target!);

    TextEditingController msgInputController = TextEditingController();

    final focusNode = FocusNode();

    return Obx(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.updateChatRoom(chatroom.target!, true, false);
      });
      return Column(
        children: [
          ...chatList()
              // ignore: unnecessary_cast
              .map((e) => ChatItem(
                    chatEvent: e,
                  ))
              .toList(),
          Column(
            children: [
              TextField(
                  controller: msgInputController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Enter Text',
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (String value) {
                    controller.sendMessage(chatroom, msgInputController.text);
                    msgInputController.clear();
                    focusNode.requestFocus();
                  }),
              TextButton(
                onPressed: () {
                  controller.sendMessage(chatroom, msgInputController.text);
                  msgInputController.clear();
                },
                child: const Text("SEND MSG"),
              )
            ],
          )
        ],
      );
    });
  }
}

class ChatItem extends StatelessWidget {
  final ChatEventModel chatEvent;
  final AuthService authService = Get.find();

  ChatItem({super.key, required this.chatEvent});

  @override
  Widget build(BuildContext context) {
    String myUserId = authService.getUser().uid;
    return Row(children: [
      Text("${(myUserId == chatEvent.source) ? "ME" : chatEvent.source}: "),
      Text("${chatEvent.message}")
    ]);
  }
}
