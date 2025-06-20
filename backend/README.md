# Cardiovascular Risk Prediction Backend

This backend service provides a REST API for cardiovascular risk prediction using a PyTorch ResNet model.

## Prerequisites

- Python 3.8 or higher
- PyTorch 1.9.0 or higher
- Flask
- Firebase Admin SDK
- Other dependencies listed in `requirements.txt`

## Installation

1. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Place your trained PyTorch model in the backend directory:
   - Save your model as `model_checkpoint.pth`
   - The model should be a ResNet architecture (ResNet50 by default)
   - The model should be saved as a checkpoint file using:
     ```python
     torch.save({
         'epoch': epoch,
         'model_state_dict': model.state_dict(),
         'optimizer_state_dict': optimizer.state_dict()
     }, 'model_checkpoint.pth')
     ```

4. Place your Firebase service account key in the backend directory:
   - Save it as `serviceAccountKey.json`

## Model Architecture

The backend uses a ResNet50 model architecture with the following modifications:
- The final fully connected layer is replaced with a single neuron for binary classification
- The model expects input images of size 224x224 with 3 channels (RGB)
- The model outputs a single value for binary classification (0 or 1)

If your model has a different architecture, you'll need to modify the model initialization code in both `app.py` and `test_model.py`.

## Running the Server

1. Start the Flask server:
```bash
# On Windows
set FLASK_APP=app.py
set FLASK_ENV=development
flask run

# On macOS/Linux
export FLASK_APP=app.py
export FLASK_ENV=development
flask run
```

2. The server will start on `http://localhost:5000`

## API Endpoints

### POST /predict
Predicts cardiovascular risk for a patient.

Request body:
```json
{
    "patientId": "patient_id_here"
}
```

Response:
```json
{
    "patientId": "patient_id_here",
    "prediction": 0,  // 0 for low risk, 1 for high risk
    "probability": 0.85,  // Confidence of the prediction
    "status": "success"
}
```

### GET /health
Health check endpoint.

Response:
```json
{
    "status": "healthy"
}
```

## Integration with Frontend

The frontend can make HTTP requests to the backend API endpoints. The backend is configured to accept CORS requests from any origin.

## Troubleshooting

1. If the model fails to load:
   - Check that `model_checkpoint.pth` exists in the backend directory
   - Verify that the model is a valid PyTorch checkpoint file
   - Ensure the model architecture matches the expected ResNet50 architecture
   - If using a different ResNet variant, update the model initialization code

2. If predictions are not working:
   - Check that the input data format matches the model's requirements
   - Verify that the patient data exists in Firestore
   - Ensure the Firebase credentials are correctly configured

3. If the server fails to start:
   - Check that all dependencies are installed
   - Verify that the Firebase service account key is present
   - Ensure no other service is using port 5000 