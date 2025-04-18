import firebase_admin
from firebase_admin import credentials, firestore
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
import os

# Step 1: Init Firebase
cred = credentials.Certificate("marketlink-app.json")  
firebase_admin.initialize_app(cred)
db = firestore.client()

# Step 2: Load Products
products_ref = db.collection("products")
products_docs = products_ref.stream()

product_texts = []
product_metadata = []

for doc in products_docs:
    data = doc.to_dict()
    text = f"{data.get('productName', '')}. {data.get('description', '')} Category: {data.get('category', '')}"
    product_texts.append(text)
    product_metadata.append({
        "type": "product",
        "id": doc.id,
        "name": data.get("productName", "")
    })

# Step 3: Load Services
services_ref = db.collection("services")
services_docs = services_ref.stream()

for doc in services_docs:
    data = doc.to_dict()
    text = f"{data.get('serviceName', '')}. {data.get('description', '')} Category: {data.get('category', '')}"
    product_texts.append(text)
    product_metadata.append({
        "type": "service",
        "id": doc.id,
        "name": data.get("serviceName", "")
    })

# Step 4: Generate Embeddings with HuggingFace
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")

# Step 5: Create and Save Vector Store
vector_store = FAISS.from_texts(product_texts, embeddings, metadatas=product_metadata)
vector_store.save_local("search_index")
