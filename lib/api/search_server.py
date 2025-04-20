from flask import Flask, request, jsonify
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
import os

app = Flask(__name__)

# Load the embeddings and FAISS index
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vector_store = FAISS.load_local("search_index", embeddings, allow_dangerous_deserialization=True)

@app.route("/search", methods=["POST"])
def search():
    data = request.get_json()
    query = data.get("query", "")
    if not query:
        return jsonify({"error": "Missing query"}), 400

    results = vector_store.similarity_search_with_score(query, k=10)
    output = []
    for doc, score in results:
        output.append({
            "content": doc.page_content,
            "metadata": doc.metadata,
            "score": score
        })
    return jsonify(output)

# Run the app
port = int(os.environ.get("PORT", 8080))
app.run(host="0.0.0.0", port=port, debug=False, use_reloader=False)
