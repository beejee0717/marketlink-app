import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/chat/chat.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/seller/bookings.dart';
import 'package:marketlinkapp/seller/home.dart';
import 'package:marketlinkapp/seller/orders.dart';

class Seller extends StatefulWidget {
  final String userId;
  const Seller({super.key, required this.userId});

  @override
  State<Seller> createState() => _SellerState();
}

class _SellerState extends State<Seller> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

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
          selectedItemColor: const Color.fromARGB(255, 119, 22, 136),
          unselectedItemColor: Colors.grey,
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
    );
  }
}
