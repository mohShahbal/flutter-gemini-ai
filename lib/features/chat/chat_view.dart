import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final List<Content> chats = [];
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  final gemini = Gemini.instance;
  bool _loading = false;
  bool get loading => _loading;
  set loading(bool set) => setState(() => _loading = set);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: const Text("Gemini ai", style: TextStyle(fontSize: 30))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chats.isNotEmpty
                  ? NotificationListener(
                      onNotification: (notification) => true,
                      child: ListView.builder(
                        controller: scrollController,
                        clipBehavior: Clip.none,
                        itemBuilder: (context, index) => MessageCard(
                          message: "${chats[index].parts!.lastOrNull!.text}",
                          role: chats[index].role!,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: chats.length,
                        reverse: false,
                        shrinkWrap: true,
                      ),
                    )
                  : const Center(child: Text('Start your chat!')),
            ),
            const SizedBox(height: 5),
            TextFieldCard(
                controller: controller, isolating: loading, send: send),
          ],
        ),
      ),
    );
  }

  send() {
    if (controller.text.trim().isNotEmpty) {
      chats.add(Content(
        role: 'user',
        parts: [Parts(text: controller.text)],
      ));
      controller.clear();
      loading = true;

      gemini.chat(chats).then(
        (value) {
          chats.add(
            Content(
              role: 'model',
              parts: [Parts(text: value?.output)],
            ),
          );

          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        },
      ).whenComplete(() {
        loading = false;
      }).onError<GeminiException>((e, _) {
        if (e.statusCode == -1) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: const Text(
                  "Your location is not supported for the API use",
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                ],
              );
            },
          );
        }
      }).timeout(
        const Duration(minutes: 1),
        onTimeout: () {
          loading = false;
          return;
        },
      );
    }
  }
}

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.message,
    required this.role,
  });

  final String message;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: role == 'user' ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 45,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
            Card(
              elevation: role == 'user' ? 1 : 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  textAlign: TextAlign.justify,
                  message,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextFieldCard extends StatelessWidget {
  const TextFieldCard({
    super.key,
    required this.controller,
    this.send,
    required this.isolating,
  });
  final TextEditingController controller;
  final bool isolating;
  final Function()? send;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 20,
      child: Card(
        margin: const EdgeInsets.fromLTRB(2, 0, 2, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          minLines: 1,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Ask me anything",
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.only(left: 15),
            suffixIcon: isolating
                ? const CircularProgressIndicator(
                    strokeAlign: -10,
                    strokeWidth: 2,
                  )
                : GestureDetector(
                    onTap: send,
                    child: const Icon(Icons.send_rounded),
                  ),
            // const SizedBox(width: 10),
          ),
        ),
      ),
    );
  }
}
