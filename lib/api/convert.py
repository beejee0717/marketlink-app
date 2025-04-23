from transformers import TFAutoModel, AutoTokenizer
import tensorflow as tf

model_name = "sentence-transformers/all-MiniLM-L6-v2"

# Load tokenizer and model
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = TFAutoModel.from_pretrained(model_name)

# Save the model in proper TensorFlow SavedModel format
# This creates the expected saved_model.pb file
tf.saved_model.save(model, "tf_model")

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_saved_model("tf_model")
tflite_model = converter.convert()

# Save the TFLite model
with open("all-MiniLM-L6-v2.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ TFLite conversion complete. Model saved as all-MiniLM-L6-v2.tflite")
