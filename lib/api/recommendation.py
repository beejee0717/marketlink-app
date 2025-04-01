import pandas as pd
import sys
import json
from surprise import Dataset, Reader, SVD

# Load and preprocess data
def load_data():
    print("Loading data...")
    df = pd.read_csv('firebase_data.csv')
    print(f"Data loaded. {len(df)} rows found.")

    # Define rating scale
    reader = Reader(rating_scale=(1, 5))

    # Load data into Surprise dataset format
    data = Dataset.load_from_df(df[['userId', 'productId', 'rating']], reader)
    
    return data, df

# Train the model
def train_model():
    print("Training model...")
    data, df = load_data()
    
    # Train on full dataset
    trainset = data.build_full_trainset()
    algo = SVD()
    algo.fit(trainset)
    
    print("Model trained successfully.")
    return algo, df

# Get top N recommendations for a user
def get_recommendations(user_id, algo, df, n=5):
    all_products = df['productId'].unique()
    predictions = [(pid, algo.predict(user_id, pid).est) for pid in all_products]

    # Sort by highest predicted rating
    top_recommendations = sorted(predictions, key=lambda x: x[1], reverse=True)[:n]
    
    # Return only document IDs
    return [prod for prod, rating in top_recommendations]

# Main function (Run this when Flutter calls it)
def get_user_recommendations(user_id):
    try:
        recommendations = ["0Zt80nuyoc0J946a3i74", "Kc1vMYzoQ3K4hwgWuYZE"]  # Dummy data for testing
        print(json.dumps(recommendations))  # Always return a JSON array
    except Exception as e:
        print(json.dumps([]))  # Return an empty list if an error occurs
        print(f"Error: {e}", file=sys.stderr)

# Run script with command-line user_id
if __name__ == "__main__":
    user_id = sys.argv[1] if len(sys.argv) > 1 else ""
    if not user_id:
        print(json.dumps([]))  # Ensure valid JSON output
        sys.exit(1)
    
    get_user_recommendations(user_id)
