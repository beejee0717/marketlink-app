import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:marketlinkapp/components/colors.dart';
import 'package:marketlinkapp/seller/service_details.dart';
import 'package:marketlinkapp/theme/event_theme.dart';
import 'package:provider/provider.dart';

import '../components/auto_size_text.dart';
import '../components/navigator.dart';
import '../components/snackbar.dart';
import '../provider/user_provider.dart';
import 'add_service.dart';

class SellerAllServices extends StatefulWidget {
  const SellerAllServices({super.key});

  @override
  State<SellerAllServices> createState() => _SellerAllServicesState();
}

class _SellerAllServicesState extends State<SellerAllServices> {
  final TextEditingController searchController = TextEditingController();
  late Stream<QuerySnapshot> servicesStream;
  late AppEvent currentEvent = getCurrentEvent();

  @override
  void initState() {
    super.initState();
    fetchServices();
  }
  Stream<bool> getSellerApprovalStatus(String sellerId) {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['approved'] == true);
  }
void fetchServices() {
  final userInfo = Provider.of<UserProvider>(context, listen: false).user;
  final sellerId = userInfo?.uid ?? "";

  String searchQuery = searchController.text.trim().toLowerCase();

  var query = FirebaseFirestore.instance
      .collection('services')
      .where('sellerId', isEqualTo: sellerId);

  if (searchQuery.isNotEmpty) {
    query = query.where('searchKeywords', arrayContains: searchQuery);
  }

  servicesStream = query.orderBy('dateCreated', descending: true).snapshots();
}


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: currentEvent == AppEvent.none ? Colors.purple.shade900 : backgroundColor(currentEvent),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            navPop(context);
          },
          icon:  Icon(
            Icons.arrow_back,
            color: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent),
          ),
        ),
        backgroundColor: Colors.transparent,
        title:  CustomText(
          textLabel: "All Services",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          textColor: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent),
        ),
      ),
      body:  Container(
        decoration: BoxDecoration(
          image: DecorationImage(image: 
          AssetImage(backgroundImage(currentEvent)),
          fit: BoxFit.cover)
        ),
        child:Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  fetchServices();
                });
              },
              style:
                  TextStyle(color:currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent), fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Search services...",
                hintStyle: TextStyle(color: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent)),
                prefixIcon: Icon(
                  Icons.search,
                  color: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent),
                ),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent))),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: currentEvent == AppEvent.none ? Colors.white : headerTitleColor(currentEvent), width: 1)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellow, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: servicesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 50),
                        child: SpinKitDoubleBounce(
                          size: 100,
                          color: Colors.yellow,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: CustomText(
                        textLabel: "Error fetching services.",
                        fontSize: 16,
                        textColor: Colors.red,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: CustomText(
                        textLabel: "No services found.",
                        fontSize: 16,
                        textColor: Colors.white,
                      ),
                    );
                  }

                  final services = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final serviceDoc = services[index];
                      final service = serviceDoc.data() as Map<String, dynamic>;
                      final serviceId = serviceDoc.id;

                      return FadeInLeft(
                        child: Card(
                          color: AppColors.transparentWhite,
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: service['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      service['imageUrl'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                            title: CustomText(
                              textLabel:
                                  service['serviceName'] ?? "Unnamed Service",
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CustomText(
                                      textLabel: "Category: ",
                                      fontSize: 14,
                                      textColor: Colors.black87,
                                    ),
                                    CustomText(
                                      textLabel:
                                          service['category'] ?? 'Uncategorized',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    CustomText(
                                      textLabel: "Price: ",
                                      fontSize: 14,
                                      textColor: Colors.black87,
                                    ),
                                    CustomText(
                                      textLabel:
                                          "₱${service['price']?.toStringAsFixed(0) ?? 'N/A'}",
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      textColor: Colors.orange,
                                    ),
                                  ],
                                ),
                               
                                const SizedBox(height: 4),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Colors.yellow.shade800,
                            ),
                            onTap: () {
                              navPush(context,
                                  SellerServiceDetails(serviceId: serviceId));
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),),
  floatingActionButton: StreamBuilder<bool>(
  stream: getSellerApprovalStatus(
    Provider.of<UserProvider>(context, listen: false).user!.uid,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
      return const SizedBox.shrink(); 
    }

    bool isApproved = snapshot.data!;

    return FloatingActionButton(
      onPressed: () {
        if (isApproved) {
          navPush(context, SellerAddService());
        } else {
          errorSnackbar(context,
              'This account is not approved yet. Please wait for admin approval before being able to sell items.');
        }
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: Colors.white),
    );
  },
),


    );
  }
}
