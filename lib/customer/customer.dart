import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/customer/cart.dart';
import 'package:marketlinkapp/customer/home.dart';
import 'package:marketlinkapp/customer/orders.dart';
import 'package:marketlinkapp/customer/wishlist.dart';

class Customer extends StatefulWidget {
  const Customer({
    super.key,
  });

  @override
  State<Customer> createState() => _CustomerState();
}

class _CustomerState extends State<Customer> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const CustomerHome(),
    const CustomerWishlist(),
    const CustomerCart(),
    const CustomerOrders()
  ];

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
          selectedItemColor: const Color.fromARGB(255, 15, 104, 176),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: 'Wishlist'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart), label: 'Cart'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
