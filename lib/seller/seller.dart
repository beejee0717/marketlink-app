import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/seller/bookings.dart';
import 'package:marketlinkapp/seller/home.dart';
import 'package:marketlinkapp/seller/orders.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class Seller extends StatefulWidget {
  final String userId;
  const Seller({super.key, required this.userId});

  @override
  State<Seller> createState() => _SellerState();
}

class _SellerState extends State<Seller> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late AppEvent currentEvent = getCurrentEvent();

  @override
  void initState() {
    super.initState();
    _pages = [
      const SellerHome(),
      const SellerOrders(),
      const SellerBookings(),
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
@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    onPopInvoked: (didPop) {
      customDialog(
        context,
        'Exit Market Link',
        'Are you sure you want to leave?',
        () {
          SystemNavigator.pop();
        },
      );
    },
    child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _pages[_selectedIndex]),
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  color: backgroundColor(currentEvent),
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
                        icon: Icon(Icons.shopping_cart_checkout_sharp),
                        label: 'Orders',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.calendar_month),
                        label: 'Booked Services',
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
        ],
      ),
    ),
  );
}
}