from flask import Flask, request, jsonify
from langchain_community.vectorstores import FAISS
from langchain_community.embeddings import HuggingFaceEmbeddings

app = Flask(__name__)

# Load embeddings and FAISS index once
embeddings = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
vector_store = FAISS.load_local("search_index", embeddings, allow_dangerous_deserialization=True)

@app.route("/search", methods=["POST"])
def search():
    data = request.get_json()
    query = data.get("query", "")
    if not query:
        return jsonify({"error": "Missing query"}), 400

    results = vector_store.similarity_search(query, k=10)
    output = []
    for result in results:
        output.append({
            "content": result.page_content,
            "metadata": result.metadata
        })
    return jsonify(output)

if __name__ == "__main__":
    app.run(debug=True)
