import torch
import torchvision.models as models
from torch import nn
import os
import numpy as np

def test_model():
    """
    Test the PyTorch ResNet model by loading it and making a sample prediction.
    """
    print("Starting model test...")
    
    # Get the path to the model file
    model_path = os.path.join(os.path.dirname(__file__), 'final_model_checkpoint1.pth')
    print(f"Looking for model at: {model_path}")
    
    if not os.path.exists(model_path):
        print(f"ERROR: Model file not found at {model_path}")
        return None, None, None, None
    
    print("Model file found. Creating ResNet model...")
    
    # Create a ResNet model
    # Using ResNet50 as a base, but you may need to adjust based on your specific model
    model = models.resnet50(weights=None)
    
    # Modify the final layer for multiple disease classification
    # Update to handle 10 diseases
    num_features = model.fc.in_features
    model.fc = nn.Sequential(
        nn.Linear(num_features, 10)  # Output 10 probabilities for 10 different diseases
    )
    
    print("Loading checkpoint...")
    
    try:
        # Load the checkpoint
        checkpoint = torch.load(model_path)
        print(f"Model loaded successfully. Checkpoint keys: {checkpoint.keys() if isinstance(checkpoint, dict) else 'Not a dictionary'}")
        
        # Check if the checkpoint has the expected structure
        if isinstance(checkpoint, dict) and 'model_state_dict' in checkpoint:
            state_dict = checkpoint['model_state_dict']
            print(f"Loaded model from epoch {checkpoint.get('epoch', 'unknown')}")
        else:
            # If the checkpoint doesn't have the expected structure, try loading it directly
            state_dict = checkpoint
            print("Loaded checkpoint directly (no 'model_state_dict' key found)")
        
        # Check if the state dict keys have the "resnet." prefix
        has_resnet_prefix = any(key.startswith("resnet.") for key in state_dict.keys())
        print(f"State dict has 'resnet.' prefix: {has_resnet_prefix}")
        
        if has_resnet_prefix:
            # Create a new state dict without the "resnet." prefix
            new_state_dict = {}
            for key, value in state_dict.items():
                if key.startswith("resnet."):
                    new_key = key[7:]  # Remove the "resnet." prefix
                    new_state_dict[new_key] = value
                else:
                    new_state_dict[key] = value
            
            # Load the modified state dict
            model.load_state_dict(new_state_dict, strict=False)
            print("Loaded model with 'resnet.' prefix removed from state dict keys")
        else:
            # Load the state dict directly
            model.load_state_dict(state_dict, strict=False)
            print("Loaded model directly from state dict")
        
        # Set the model to evaluation mode
        model.eval()
        print("Model set to evaluation mode")
        
        # Create a sample input tensor
        # For ResNet, we need an image tensor of size [batch_size, channels, height, width]
        # This is a placeholder - you'll need to adjust based on your actual model's input requirements
        sample_input = torch.randn(1, 3, 224, 224)  # Batch size 1, 3 channels, 224x224 image
        print(f"Created sample input tensor with shape: {sample_input.shape}")
        
        # Make a prediction
        print("Making prediction...")
        with torch.no_grad():
            outputs = model(sample_input)
            print(f"Model output shape: {outputs.shape}")
            
            # Apply sigmoid to get probabilities for each disease
            probabilities = torch.sigmoid(outputs).numpy()[0]
            print(f"Probabilities shape: {probabilities.shape}")
            
            # Define disease names (adjust based on your actual model)
            # This is a placeholder - you should replace with your actual 10 disease names
            disease_names = [f"Disease_{i+1}" for i in range(10)]
            
            # Create a dictionary of disease probabilities
            disease_probabilities = {
                disease_names[i]: float(probabilities[i]) 
                for i in range(len(disease_names))
            }
            
            # Get the top 10 most probable diseases
            sorted_diseases = sorted(disease_probabilities.items(), key=lambda x: x[1], reverse=True)
            top_10_diseases = dict(sorted_diseases[:10])
            print(f"Top 10 diseases: {top_10_diseases}")
            
            # Calculate ROC curve data (simplified)
            # In a real implementation, you would need true labels for each disease
            # This is a placeholder that creates synthetic ROC data
            roc_data = {}
            for disease, prob in top_10_diseases.items():
                # Create synthetic ROC curve points (10 points)
                fpr = np.linspace(0, 1, 10)
                tpr = np.array([prob * (1 - p) + p for p in fpr])  # Simplified ROC curve
                roc_data[disease] = {
                    'fpr': fpr.tolist(),
                    'tpr': tpr.tolist(),
                    'auc': float(prob)  # Simplified AUC (not accurate)
                }
            
            print("Model test completed successfully!")
            return model, disease_probabilities, top_10_diseases, roc_data
            
    except Exception as e:
        print(f"Error testing model: {str(e)}")
        import traceback
        traceback.print_exc()
        return None, None, None, None

if __name__ == "__main__":
    print("Starting test_model.py script...")
    try:
        model, disease_probabilities, top_10_diseases, roc_data = test_model()
        if model is not None:
            print("Test completed successfully!")
            print("\nModel Test Results:")
            print(f"Total diseases: {len(disease_probabilities)}")
            print("\nTop 10 Diseases:")
            for disease, probability in top_10_diseases.items():
                print(f"{disease}: {probability:.2%}")
        else:
            print("Test failed to complete.")
    except Exception as e:
        print(f"Error testing model: {str(e)}") 