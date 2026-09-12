import os
from dotenv import load_dotenv
from roboflow import Roboflow

load_dotenv()

api_key = os.getenv("ROBOFLOW_API_KEY")
if not api_key:
    print("ROBOFLOW_API_KEY environment variable is not set.")
    exit(1)

print("Connecting to Roboflow...")
rf = Roboflow(api_key=api_key)

print("Accessing workspace and project...")
project = rf.workspace("prism-bbnrh").project("e-waste-dataset-r0ojc-p3l7i")

print("Downloading dataset (version 2)...")
version = project.version(2)
# Download in a format, e.g. YOLOv8
dataset = version.download("yolov8")

print(f"Dataset downloaded successfully to: {dataset.location}")
