import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/components/dialog.dart';
import 'package:marketlinkapp/customer/cart.dart';
import 'package:marketlinkapp/customer/home.dart';
import 'package:marketlinkapp/customer/orders.dart';
import 'package:marketlinkapp/customer/wishlist.dart';
import 'package:marketlinkapp/theme/event_theme.dart';

class Customer extends StatefulWidget {
  const Customer({
    super.key,
  });

  @override
  State<Customer> createState() => _CustomerState();
}
class _CustomerState extends State<Customer> {
  int _selectedIndex = 0;
  late AppEvent currentEvent;

  final List<Widget> _pages = [
    const CustomerHome(),
    const CustomerWishlist(),
    const CustomerCart(),
    const CustomerOrders()
  ];

  @override
  void initState() {
    super.initState();
    currentEvent = getCurrentEvent();
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
      customDialog(context, 'Exit Market Link',
          'Are you sure you want to leave?', () {
        SystemNavigator.pop();
      });
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
                  decoration: BoxDecoration(
                   color: backgroundColor(currentEvent)
                  ),
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
                        icon: Icon(Icons.favorite),
                        label: 'Wishlist',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.shopping_cart),
                        label: 'Cart'),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.receipt_long),
                        label: 'Orders'),
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
