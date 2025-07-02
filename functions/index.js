const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

//seller notif when new orders
exports.notifySellerOnNewOrder = functions.firestore
    .document("orders/{orderId}")
    .onCreate(async (snap, context) => {
        const order = snap.data();
        const sellerId = order.sellerId;

        const sellerDoc = await admin.firestore().collection("sellers").doc(sellerId).get();
        const fcmToken = sellerDoc.data()?.fcmToken;

        if (fcmToken) {
            const message = {
                token: fcmToken,
                notification: {
                    title: "New Order Received!",
                    body: "You received a new order. Check your seller dashboard.",
                },
            };
            await admin.messaging().send(message);
        }
    });

// customer notif for order updates
exports.notifyCustomerOnOrderUpdate = functions.firestore
    .document("orders/{orderId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.status !== after.status) {
            const customerId = after.customerId;
            const customerDoc = await admin.firestore().collection("customers").doc(customerId).get();
            const fcmToken = customerDoc.data()?.fcmToken;

            if (fcmToken) {
                const message = {
                    token: fcmToken,
                    notification: {
                        title: "Order Status Updated",
                        body: `Your order is now "${after.status}".`,
                    },
                };
                await admin.messaging().send(message);
            }
        }
    });
