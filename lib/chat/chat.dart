import 'package:flutter/material.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/dialog.dart';
import '../provider/chat_provider.dart';
import 'messages.dart';

class Chat extends StatefulWidget {
  final String userId;
  final bool backButton;

  const Chat({required this.userId, super.key, required this.backButton});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late ChatProvider _chatProvider;
  late AppEvent currentEvent = getCurrentEvent();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _chatProvider.initialize(widget.userId, context);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatProvider>.value(
      value: _chatProvider,
      child: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return ModalProgressHUD(
            inAsyncCall: _isLoading,
            color: Colors.black,
            progressIndicator: CircularProgressIndicator(
              color: Colors.white,
            ),
            child: Scaffold(
              appBar: AppBar(
                leading: widget.backButton
                    ? IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: screenWidth(0.07, context),
                        ),
                        style: ButtonStyle(
                          overlayColor:
                              const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color?>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return const Color.fromARGB(255, 0, 255, 8);
                              } else {
                                return headerTitleColor(currentEvent);
                              }
                            },
                          ),
                        ))
                    : null,
                backgroundColor: backgroundColor(currentEvent),
                title: CustomText(
                  textLabel: 'Chat',
                  fontSize: 22,
                  letterSpacing: 2,
                  textColor: headerTitleColor(currentEvent),
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(backgroundImage(currentEvent)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: provider.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                            color: Colors.purple,
                          ))
                        : provider.chatRooms.isEmpty
                            ? const Center(
                                child: CustomText(
                                  textLabel: 'No Chat History',
                                  fontSize: 20,
                                  textColor: Colors.black,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.separated(
                                separatorBuilder: (context, index) {
                                  return SizedBox(
                                    height: screenHeight(0.02, context),
                                  );
                                },
                                itemCount: provider.chatRooms.length,
                                itemBuilder: (context, index) {
                                  var chatRoom = provider.chatRooms[index];
                                  return ListTile(
                                    
                                    leading: Container(
                                      
                                      width: screenWidth(0.15, context),
                                      height: screenWidth(0.15, context),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 255, 255, 255),
                                        border: Border.all(
                                            width: 2, color: Colors.black54),
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: chatRoom['profilePicture'] !=
                                                      null &&
                                                  chatRoom['profilePicture']
                                                      .isNotEmpty
                                              ? NetworkImage(
                                                  chatRoom['profilePicture'])
                                              : const AssetImage(
                                                      'assets/images/profile.png')
                                                  as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    title: CustomText(
                                      textLabel: chatRoom['otherName'],
                                      fontSize: 20,
                                      textColor: Colors.black,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Color.fromARGB(255, 155, 15, 5),
                                      ),
                                      onPressed: () async {
                                        customDialog(context, 'Remove User',
                                            'Are you sure you want to remove this user? Chat history will be deleted.',
                                            () async {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          Navigator.pop(context);
                                          await _chatProvider.deleteUser(
                                              context,
                                              widget.userId,
                                              chatRoom['otherUserId']);
                                          if (!context.mounted) return;
                                          await _chatProvider.initialize(
                                              widget.userId, context);

                                          await Future.delayed(
                                              const Duration(seconds: 1));
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        });
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserMessages(
                                            userId: widget.userId,
                                            receiverUserId:
                                                chatRoom['otherUserId'],
                                            receiverFirstName:
                                                chatRoom['firstName'],
                                            receiverProfilePic:
                                                chatRoom['profilePicture'] ??
                                                    'assets/images/profile.png',
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

double screenHeight(double height, BuildContext context) {
  return MediaQuery.of(context).size.height * height;
}

double screenWidth(double width, BuildContext context) {
  return MediaQuery.of(context).size.width * width;
}
