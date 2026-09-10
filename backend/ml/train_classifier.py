import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
import numpy as np
import os
import json

# Config
IMG_SIZE = 224
BATCH_SIZE = 16
EPOCHS_FROZEN = 5      # train only new head first
EPOCHS_FINETUNE = 5    # then unfreeze top layers
DATASET_DIR = 'dataset'
OUTPUT_DIR = 'output'
os.makedirs(OUTPUT_DIR, exist_ok=True)

CATEGORIES = ['Battery', 'Cable', 'CRT', 'LCD', 'Mixed', 'Motor', 'PCB', 'Plastic']

# Load dataset
train_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.2,
    subset='training',
    seed=42,
    image_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_names=CATEGORIES,
)

val_ds = tf.keras.utils.image_dataset_from_directory(
    DATASET_DIR,
    validation_split=0.2,
    subset='validation',
    seed=42,
    image_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_names=CATEGORIES,
)

# Prefetch for performance
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

# Data augmentation (important with small dataset)
augmentation = tf.keras.Sequential([
    layers.RandomFlip('horizontal'),
    layers.RandomRotation(0.15),
    layers.RandomZoom(0.1),
    layers.RandomBrightness(0.1),
])

# Build model
base_model = MobileNetV2(
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False  # freeze base first

inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
x = augmentation(inputs)
x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(len(CATEGORIES), activation='softmax')(x)

model = models.Model(inputs, outputs)

# Phase 1 — train head only
model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-3),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)
model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS_FROZEN)

# Phase 2 — fine-tune top 30 layers
base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-5),  # lower LR for fine-tuning
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)
model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS_FINETUNE)

# Save validation accuracy
_, val_acc = model.evaluate(val_ds)
print(f"\nFinal validation accuracy: {val_acc:.2%}")
print("(This is what you report to SIH judges)")

# Export to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # quantization → smaller model
tflite_model = converter.convert()

model_path = os.path.join(OUTPUT_DIR, 'material_classifier.tflite')
with open(model_path, 'wb') as f:
    f.write(tflite_model)

print(f"Model saved: {model_path}")
print(f"Model size: {os.path.getsize(model_path) / 1024 / 1024:.1f} MB")

# Save labels
labels_path = os.path.join(OUTPUT_DIR, 'labels.txt')
with open(labels_path, 'w') as f:
    f.write('\n'.join(CATEGORIES))

# Save metadata for the app
metadata = {
    'categories': CATEGORIES,
    'input_size': IMG_SIZE,
    'validation_accuracy': float(val_acc),
    'total_training_images': 480,
    'note': 'MobileNetV2 transfer learning, quantized'
}
with open(os.path.join(OUTPUT_DIR, 'model_metadata.json'), 'w') as f:
    json.dump(metadata, f, indent=2)

print("Labels and metadata saved.")
print("\nNext: copy output/material_classifier.tflite and output/labels.txt")
print("to collector_app/assets/ml/")
