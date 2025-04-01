import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

cred = credentials.Certificate("marketlink-app.json")  
firebase_admin.initialize_app(cred)

db = firestore.client()

data = []

# Fetch user search history
users_ref = db.collection('customers')
users = users_ref.stream()

for user in users:
    user_id = user.id
    
    # Fetch search history
    searches_ref = users_ref.document(user_id).collection('searchHistory').stream()
    for search in searches_ref:
        data.append([user_id, search.get('query'), 1.0]) 

    # Fetch product clicks (FIXED: Get actual product ID instead of product name)
    clicks_ref = users_ref.document(user_id).collection('productClicks').stream()
    for click in clicks_ref:
        product_name = click.get('productName')  
        
        # Query Firestore to find the product document ID
        product_query = db.collection('products').where('productName', '==', product_name).limit(1).stream()
        product_doc = next(product_query, None)  # Get first matching document
        
        if product_doc:
            product_id = product_doc.id  # Use document ID instead of product name
            data.append([user_id, product_id, 3.0]) 

    # Fetch purchase history
    purchases_ref = users_ref.document(user_id).collection('purchaseHistory').stream()
    for purchase in purchases_ref:
        data.append([user_id, purchase.get('productId'), 5.0]) 

df = pd.DataFrame(data, columns=['userId', 'productId', 'rating'])
df.to_csv("firebase_data.csv", index=False)

print("Data exported successfully!")
