import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/rider/home.dart';
import 'package:marketlinkapp/seller/orders.dart';

class Rider extends StatefulWidget {
  final String userId;
  const Rider({super.key, required this.userId});

  @override
  State<Rider> createState() => _RiderState();
}

class _RiderState extends State<Rider> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const RiderHome(),
      const SellerOrders(),
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
       bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.purple,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            
            BottomNavigationBarItem(
                icon: Icon(Icons.list), label: 'Deliveries'),
         BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}
