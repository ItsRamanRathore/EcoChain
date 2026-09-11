import os
import tensorflow as tf
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
import numpy as np
from PIL import Image

# Configuration
IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 5
DATASET_DIR = "dataset"
MODEL_SAVE_PATH = "material_classifier.tflite"

LABELS = ["Battery", "Cable", "CRT", "LCD", "Mixed", "Motor", "PCB", "Plastic"]

def create_dummy_dataset():
    """
    Creates a dummy dataset if one doesn't exist so the script runs without breaking.
    In a real scenario, replace this folder with actual images of e-waste.
    """
    print("Checking dataset...")
    if not os.path.exists(DATASET_DIR):
        os.makedirs(DATASET_DIR)
        
    for i, label in enumerate(LABELS):
        label_dir = os.path.join(DATASET_DIR, label)
        if not os.path.exists(label_dir):
            os.makedirs(label_dir)
            # Generate 10 dummy images per class (solid colors based on index)
            for j in range(10):
                color = ( (i*30)%255, (i*50)%255, (i*70)%255 )
                img = Image.new('RGB', IMAGE_SIZE, color=color)
                img.save(os.path.join(label_dir, f"dummy_{j}.jpg"))
    print(f"Dataset ready at {DATASET_DIR}/. Replace these with real images for an accurate model.")

def build_model(num_classes):
    # Load MobileNetV2 without the top classification layer
    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    
    # Freeze the base model
    base_model.trainable = False
    
    # Add custom classification head
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    predictions = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=base_model.input, outputs=predictions)
    model.compile(optimizer=Adam(learning_rate=0.001), 
                  loss='sparse_categorical_crossentropy', 
                  metrics=['accuracy'])
    return model

def train_and_export():
    create_dummy_dataset()
    
    print("Loading dataset...")
    # Load dataset from directory
    train_ds = tf.keras.utils.image_dataset_from_directory(
        DATASET_DIR,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
    )
    
    val_ds = tf.keras.utils.image_dataset_from_directory(
        DATASET_DIR,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=IMAGE_SIZE,
        batch_size=BATCH_SIZE,
    )
    
    class_names = train_ds.class_names
    print(f"Classes found: {class_names}")
    
    # Normalization layer (MobileNetV2 expects [0, 1] or [-1, 1], we use [0, 1] scaling)
    normalization_layer = tf.keras.layers.Rescaling(1./255)
    train_ds = train_ds.map(lambda x, y: (normalization_layer(x), y))
    val_ds = val_ds.map(lambda x, y: (normalization_layer(x), y))
    
    # Ensure classes match our expected labels
    if sorted(class_names) != sorted(LABELS):
        print(f"WARNING: Found classes {class_names} but expected {LABELS}")

    print("Building model...")
    model = build_model(len(class_names))
    
    print("Training model...")
    model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS)
    
    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Enable optimizations for mobile
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open(MODEL_SAVE_PATH, "wb") as f:
        f.write(tflite_model)
        
    print(f"Success! Model saved to {MODEL_SAVE_PATH}")
    print("Copy this file to: collector_app/assets/ml/material_classifier.tflite")

if __name__ == "__main__":
    train_and_export()
