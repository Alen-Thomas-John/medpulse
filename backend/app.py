from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import torch
import os
import firebase_admin
from firebase_admin import credentials, firestore, initialize_app
import torch.nn as nn
import torchvision.models as models
import json
from PIL import Image
import io
import base64
import requests
from urllib.parse import unquote
from torchvision import transforms
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize Firebase with error handling
db = None  # Initialize db as None by default
try:
    cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
    if not os.path.exists(cred_path):
        print(f"Warning: Firebase credentials file not found at {cred_path}")
        print("Please ensure the Firebase credentials file is in the correct location")
    else:
        cred = credentials.Certificate(cred_path)
        initialize_app(cred)
        db = firestore.client()
        print("Firebase initialized successfully")
except Exception as e:
    print(f"Error initializing Firebase: {str(e)}")
    print("Database operations will not be available")

# Define the model architecture to match the training code
class CombinedModel(nn.Module):
    def __init__(self, num_diseases=10):
        super(CombinedModel, self).__init__()
        self.cnn = models.resnet50(weights=None)
        self.cnn.fc = nn.Identity()  # Remove last layer

        self.structured_net = nn.Sequential(
            nn.Linear(12, 64),  # 12 structured features
            nn.ReLU(),
            nn.Linear(64, 32),
            nn.ReLU()
        )

        self.classifier = nn.Sequential(
            nn.Linear(2048 + 32, 128),
            nn.ReLU(),
            nn.Linear(128, num_diseases),
            nn.Sigmoid()
        )

    def forward(self, image, structured):
        img_features = self.cnn(image)
        structured_features = self.structured_net(structured)
        combined = torch.cat((img_features, structured_features), dim=1)
        output = self.classifier(combined)
        return output

# Create model instance
model = CombinedModel(num_diseases=10)  # 10 diseases as per training code

# Load the trained model
try:
    model_path = os.path.join(os.path.dirname(__file__), 'final_model_checkpoint2.pth')
    if not os.path.exists(model_path):
        print(f"Error: Model file not found at {model_path}")
        print("Please ensure the model file is in the correct location")
        model = None
    else:
        print(f"Loading model from {model_path}")
        model = CombinedModel()
        checkpoint = torch.load(model_path, map_location=torch.device('cpu'))
        
        # Handle different checkpoint formats
        if isinstance(checkpoint, dict):
            if 'model_state_dict' in checkpoint:
                state_dict = checkpoint['model_state_dict']
            else:
                state_dict = checkpoint
        else:
            state_dict = checkpoint
            
        # Remove 'module.' prefix if present
        state_dict = {k.replace('module.', ''): v for k, v in state_dict.items()}
        
        model.load_state_dict(state_dict)
        model.eval()
        print("Model loaded successfully")
except Exception as e:
    print(f"Error loading model: {str(e)}")
    model = None

# Set model to evaluation mode
model.eval()
print("Model set to evaluation mode")

# Image preprocessing
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
])

def extract_features(patient_data):
    """
    Extract features from patient data for model prediction.
    
    Args:
        patient_data (dict): Dictionary containing patient information
        
    Returns:
        tuple: (image_tensor, structured_tensor) or (None, None) if extraction fails
    """
    try:
        print("Starting feature extraction")
        
        # Extract structured features
        structured_features = [
            float(patient_data.get('gender', 'M') == 'M'),  # Convert gender to binary
            float(patient_data.get('anchorAge', 0)),
            float(patient_data.get('heartRate', 0)),
            float(patient_data.get('arterialBloodPressureSystolic', 0)),
            float(patient_data.get('arterialBloodPressureDiastolic', 0)),
            float(patient_data.get('respiratoryRate', 0)),
            float(patient_data.get('spo2', 0)),
            float(patient_data.get('glucoseSerum', 0)),
            float(patient_data.get('sodium', 0)),
            float(patient_data.get('temperatureCelsius', 0)),
            float(patient_data.get('cholesterol', 0)),
            float(patient_data.get('hemoglobin', 0))
        ]
        
        # Convert to tensor
        structured_tensor = torch.tensor(structured_features, dtype=torch.float32).unsqueeze(0)
        print(f"Structured features extracted: {structured_tensor.shape}")
        
        # Process image if available
        image_tensor = None
        if 'imageUrls' in patient_data and patient_data['imageUrls']:
            print(f"Found {len(patient_data['imageUrls'])} images")
            
            # Try each image URL until one works
            for image_url in patient_data['imageUrls']:
                print(f"Trying to process image URL: {image_url}")
                
                try:
                    # Download image from Cloudinary
                    response = requests.get(image_url, timeout=10)
                    if response.status_code == 200:
                        # Open image
                        image = Image.open(io.BytesIO(response.content)).convert('RGB')
                        
                        # Transform image
                        image_tensor = transform(image).unsqueeze(0)
                        print(f"Successfully processed image. Tensor shape: {image_tensor.shape}")
                        break  # Exit loop if image was successfully processed
                    else:
                        print(f"Failed to download image: HTTP {response.status_code}")
                except requests.exceptions.Timeout:
                    print(f"Timeout while downloading image from {image_url}")
                except requests.exceptions.RequestException as e:
                    print(f"Request error while downloading image: {e}")
                except Exception as e:
                    print(f"Error processing image: {e}")
        
        if image_tensor is None:
            # Create a placeholder image tensor if no image is available or processing failed
            image_tensor = torch.zeros((1, 3, 224, 224), dtype=torch.float32)
            print("Using placeholder image tensor")
        
        return image_tensor, structured_tensor
            
    except Exception as e:
        print(f"Error during feature extraction: {e}")
        return None, None

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if model is None:
            return jsonify({'error': 'Model not loaded'}), 500
            
        if db is None:
            return jsonify({'error': 'Database not initialized. Please check Firebase credentials.'}), 500
            
        data = request.get_json()
        patient_id = data.get('patient_id')
        
        if not patient_id:
            return jsonify({'error': 'Patient ID is required'}), 400
            
        print(f"Processing prediction request for patient ID: {patient_id}")
        
        # Get patient data from Firestore
        try:
            patient_ref = db.collection('patients').document(patient_id)
            patient_doc = patient_ref.get()
            
            if not patient_doc.exists:
                print(f"Patient not found in Firestore: {patient_id}")
                return jsonify({'error': 'Patient not found'}), 404
            
            patient_data = patient_doc.to_dict()
            print(f"Retrieved patient data: {patient_data}")
        except Exception as e:
            print(f"Error accessing Firestore: {str(e)}")
            return jsonify({'error': 'Error accessing database'}), 500
        
        # Extract features from patient data
        image_tensor, structured_tensor = extract_features(patient_data)
        
        if image_tensor is None or structured_tensor is None:
            print("Failed to extract features for prediction")
            return jsonify({'error': 'Failed to extract features for prediction'}), 400
        
        # Make prediction
        with torch.no_grad():
            outputs = model(image_tensor, structured_tensor)
            print(f"Model output shape: {outputs.shape}")
            probabilities = outputs.squeeze().numpy()
            print(f"Probabilities shape: {probabilities.shape}")
        
        # Get top 10 diseases with their probabilities
        top_indices = np.argsort(probabilities)[-10:][::-1]  # Get top 10 indices in descending order
        top_diseases = [{"index": int(idx), "probability": float(probabilities[idx])} for idx in top_indices]
        print(f"Top 10 diseases: {top_diseases}")
        
        # Generate ROC curve data
        roc_data = {}
        for disease in top_diseases:
            index = disease['index']
            roc_data[str(index)] = {
                'true_positive_rate': 0.8,  # Placeholder value
                'false_positive_rate': 0.2,  # Placeholder value
                'auc': 0.75  # Placeholder value
            }
        
        print(f"Generated ROC data: {roc_data}")  # Debug print
        
        # Update Firestore with prediction results
        try:
            patient_ref = db.collection('patients').document(patient_id)
            prediction_data = {
                'prediction_results': {
                    'top_10_diseases': top_diseases,
                    'roc_data': roc_data,
                    'timestamp': datetime.now().isoformat()
                }
            }
            print(f"Updating Firestore with data: {prediction_data}")  # Debug print
            patient_ref.update(prediction_data)
            print(f"Updated Firestore with prediction results for patient: {patient_id}")
        except Exception as e:
            print(f"Error updating Firestore with prediction results: {e}")
        
        return jsonify({
            'patient_id': patient_id,
            'predictions': top_diseases,
            'roc_data': roc_data
        })
    
    except Exception as e:
        print(f"Error during prediction: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'database_initialized': db is not None
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
