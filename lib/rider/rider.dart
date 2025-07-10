import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/rider/deliveries.dart';
import 'package:marketlinkapp/rider/home.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class Rider extends StatefulWidget {
  final String userId;
  const Rider({super.key, required this.userId});

  @override
  State<Rider> createState() => _RiderState();
}

class _RiderState extends State<Rider> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late AppEvent currentEvent = getCurrentEvent();

  @override
  void initState() {
    super.initState();
    _pages = [
      const RiderHome(),
      const RiderDeliveries(),
      Chat(
        userId: widget.userId,
        backButton: false,
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        customDialog(
            context, 'Exit Market Link', 'Are you sure you want to leave?', () {
          SystemNavigator.pop();
        });
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
   bottomNavigationBar: Stack(
  children: [
    Container(
      height: 60,
      width: double.infinity,
      color: backgroundColor(currentEvent), // <- Event-based background
    ),
    SizedBox(
      height: 60,
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Deliveries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    ),
  ],
),
   ),
    );
  }
}
