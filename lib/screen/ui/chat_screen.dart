import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  WebSocketChannel? channel;
  final Dio dio = Dio();

  final TextEditingController controller = TextEditingController();

  List<Map<String, String>> messages = [];

  final String userId = "11";

  bool isSocketConnected = false;

  @override
  void initState() {
    super.initState();
    connectSocket();
  }

  /// =========================
  /// CONNECT SOCKET
  /// =========================
  void connectSocket() {
    isSocketConnected = false;

    channel = WebSocketChannel.connect(
      Uri.parse("wss://9bf0-103-99-181-58.ngrok-free.app/ws/chat"),
    );

    channel!.stream.listen(
          (data) {
        final decoded = jsonDecode(data);

        if (!mounted) return;

        setState(() {
          messages.add({
            "sender": "ai",
            "text": decoded["message"] ?? data.toString(),
          });
        });
      },
      onError: (error) {
        print("Socket error: $error");
        setState(() {
          isSocketConnected = false;
        });
      },
      onDone: () {
        print("Socket closed");
        setState(() {
          isSocketConnected = false;
        });
      },
    );

    /// INIT MESSAGE
    channel!.sink.add(jsonEncode({
      "user_id": userId,
    }));

    setState(() {
      isSocketConnected = true;
    });
  }

  /// =========================
  /// SEND MESSAGE
  /// =========================
  void sendMessage() {
    if (controller.text.isEmpty) return;
    if (!isSocketConnected) return;

    final text = controller.text;

    setState(() {
      messages.add({
        "sender": "user",
        "text": text,
      });
    });

    channel!.sink.add(jsonEncode({
      "message": text,
    }));

    controller.clear();
  }

  @override
  void dispose() {
    channel?.sink.close();
    controller.dispose();
    super.dispose();
  }

  /// =========================
  /// MESSAGE UI
  /// =========================
  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg["sender"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg["text"] ?? "",
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          title: const Text("AI Chat"),
          backgroundColor: Colors.blue,
        ),

        body: Column(
          children: [
            /// =========================
            /// CHAT LIST (REVERSED)
            /// =========================
            Expanded(
              child: ListView.builder(
                reverse: true, // 🔥 KEY FIX
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  return buildMessage(msg);
                },
              ),
            ),

            /// =========================
            /// INPUT AREA
            /// =========================
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: isSocketConnected,
                      decoration: const InputDecoration(
                        hintText: "Type message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isSocketConnected ? sendMessage : null,
                    child: const Text("Send"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}