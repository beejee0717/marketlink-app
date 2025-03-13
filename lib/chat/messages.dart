import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../provider/chat_provider.dart';
import '../provider/user_provider.dart';
import 'chat.dart';

class UserMessages extends StatefulWidget {
  final String userId;
  final String receiverUserId;
  final String receiverFirstName;
  final String receiverProfilePic;

  const UserMessages(
      {required this.userId,
      required this.receiverUserId,
      required this.receiverFirstName,
      required this.receiverProfilePic,
      super.key});

  @override
  State<UserMessages> createState() => _UserMessagesState();
}

class _UserMessagesState extends State<UserMessages> {
  final TextEditingController _messageController = TextEditingController();
  final MessagesProvider _messagesProvider = MessagesProvider();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  late Stream<QuerySnapshot> _messageStream;

  @override
  void initState() {
    super.initState();
    _messageStream =
        _messagesProvider.getMessages(widget.receiverUserId, widget.userId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
    _messageFocus.addListener(() {
      if (_messageFocus.hasFocus) {
        scrollToBottom();
      }
    });
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() async {
    final userInfo = Provider.of<UserProvider>(context, listen: false).user;
    if (_messageController.text.isNotEmpty && userInfo != null) {
      await _messagesProvider.sendMessage(
        widget.receiverUserId,
        _messageController.text,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ButtonStyle(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color.fromARGB(255, 0, 255, 8);
                } else {
                  return Colors.white;
                }
              },
            ),
          ),
          icon: Icon(
            Icons.arrow_back,
            size: screenWidth(0.06, context),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 68, 28, 96),
        title: CustomText(
          textLabel: widget.receiverFirstName,
          fontSize: 22,
          textColor: Colors.white,
          letterSpacing: 2,
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: buildMessageList(),
            ),
            buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messageStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  textLabel: 'Start the conversation!',
                  fontSize: 22,
                  letterSpacing: 1,
                  textColor: Colors.black45,
                ),
                SizedBox(height: 10),
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black45,
                  size: 40,
                ),
              ],
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });

        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs
              .map((document) => buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  Widget buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    bool isSender = data['senderId'] == widget.userId;
    var alignment = isSender ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSender)
            CircleAvatar(
              radius: 30,
              backgroundImage: widget.receiverProfilePic.isNotEmpty
                  ? NetworkImage(widget.receiverProfilePic)
                  : const AssetImage('assets/images/profilepic.jpg')
                      as ImageProvider,
              onBackgroundImageError: (_, __) {
                setState(() {});
              },
              child: widget.receiverProfilePic.isEmpty
                  ? Image.asset('assets/images/profilepic.jpg',
                      fit: BoxFit.cover)
                  : null,
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSender ? Colors.purple : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                data['message'],
                style: TextStyle(
                    color: isSender ? Colors.white : Colors.black,
                    fontSize: 18,
                    letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            maxLength: 200,
            controller: _messageController,
            focusNode: _messageFocus,
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.only(left: 20, bottom: 5),
              hintText: 'Enter your message...',
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onFieldSubmitted: (value) {
              _messageController.text = '${_messageController.text}\n';
              _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length));
            },
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.send,
            color: Color.fromARGB(255, 93, 0, 109),
          ),
          onPressed: () {
            sendMessage();
            _messageController.clear();
          },
        ),
      ],
    );
  }
}
