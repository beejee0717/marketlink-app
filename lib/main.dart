import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/api/embedding_generator.dart';
import 'package:marketlinkapp/notif.dart';
import 'package:marketlinkapp/onboarding/onboarding.dart';
import 'package:marketlinkapp/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'provider/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
await EmbeddingGenerator().loadModel();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyB4UWfGlb8m4qvfYcaI3JMSff0h7FFHQc4',
      appId: '1:1023416116583:android:33965ef7c9d74f2f1cfbc2',
      messagingSenderId: '1023416116583',
      projectId: 'marketlink-app',
    ),
  );
  await FirebaseMessaging.instance.requestPermission();

  await NotificationService.init();
  runApp(const MarketLink());
}

class MarketLink extends StatelessWidget {
  const MarketLink({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => UserProvider(),
          ),
          ChangeNotifierProvider(
            create: (context) => ChatProvider(),
          ),
        ],
        child: MaterialApp(
            title: 'MarketLink App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: Onboarding()));
  }
}
