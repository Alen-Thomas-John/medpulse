import os
import sys
import subprocess
import platform

def check_python_version():
    """Check if Python version is 3.8 or higher"""
    if sys.version_info < (3, 8):
        print("Error: Python 3.8 or higher is required")
        sys.exit(1)
    print(f"Python version: {sys.version.split()[0]} ✓")

def create_virtual_environment():
    """Create a virtual environment if it doesn't exist"""
    if not os.path.exists("venv"):
        print("Creating virtual environment...")
        subprocess.run([sys.executable, "-m", "venv", "venv"])
        print("Virtual environment created ✓")
    else:
        print("Virtual environment already exists ✓")

def install_dependencies():
    """Install required packages"""
    print("Installing dependencies...")
    
    # Determine the pip path based on the platform
    if platform.system() == "Windows":
        pip_path = os.path.join("venv", "Scripts", "pip")
    else:
        pip_path = os.path.join("venv", "bin", "pip")
    
    # Install dependencies
    subprocess.run([pip_path, "install", "-r", "requirements.txt"])
    print("Dependencies installed ✓")

def check_model_file():
    """Check if model_checkpoint.pth exists"""
    if not os.path.exists("model_checkpoint.pth"):
        print("Warning: model_checkpoint.pth not found. Please place your trained PyTorch model in the backend directory.")
    else:
        print("model_checkpoint.pth found ✓")

def check_firebase_credentials():
    """Check if serviceAccountKey.json exists"""
    if not os.path.exists("serviceAccountKey.json"):
        print("Warning: serviceAccountKey.json not found. Please download it from Firebase Console.")
    else:
        print("serviceAccountKey.json found ✓")

def main():
    print("=== MedPulse Backend Setup ===")
    check_python_version()
    create_virtual_environment()
    install_dependencies()
    check_model_file()
    check_firebase_credentials()
    
    print("\nSetup complete! To run the server:")
    if platform.system() == "Windows":
        print("  venv\\Scripts\\python app.py")
    else:
        print("  venv/bin/python app.py")

if __name__ == "__main__":
    main() 