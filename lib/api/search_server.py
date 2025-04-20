from flask import Flask, request, jsonify
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings
import os

app = Flask(__name__)

print("[INFO] Initializing embeddings and vector store...")
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vector_store = FAISS.load_local("search_index", embeddings, allow_dangerous_deserialization=True)
print("[INFO] Vector store loaded.")

@app.route("/search", methods=["POST"])
def search():
    try:
        print("[INFO] Received request")
        data = request.get_json()
        query = data.get("query", "")
        print(f"[INFO] Query: {query}")

        if not query:
            return jsonify({"error": "Missing query"}), 400

        print("[INFO] Performing similarity search...")
        results = vector_store.similarity_search_with_score(query, k=10)
        output = []

        for doc, score in results:
            output.append({
                "content": doc.page_content,
                "metadata": doc.metadata,
                "score": score
            })

        print("[INFO] Search complete, returning results.")
        return jsonify(output)

    except Exception as e:
        print(f"[ERROR] {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

port = int(os.environ.get("PORT", 8080))
print(f"[INFO] Server starting on port {port}...")
app.run(host="0.0.0.0", port=port, debug=False, use_reloader=False)
