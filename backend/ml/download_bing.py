import os
import shutil
from bing_image_downloader import downloader

LABELS = ["Battery", "Cable", "CRT", "LCD", "Mixed", "Motor", "PCB", "Plastic"]
DATASET_DIR = "dataset"
IMAGES_PER_CLASS = 50

def clean_dataset():
    if os.path.exists(DATASET_DIR):
        print("Cleaning up old dataset directory to remove dummy images...")
        shutil.rmtree(DATASET_DIR)
    os.makedirs(DATASET_DIR)

def main():
    clean_dataset()
    
    print(f"Starting download of {IMAGES_PER_CLASS} real images per category using Bing Image Downloader...")
    
    for label in LABELS:
        query = f"e-waste {label}"
        print(f"\n--- Downloading images for {label} ---")
        try:
            downloader.download(query, limit=IMAGES_PER_CLASS,  output_dir=DATASET_DIR, 
                                adult_filter_off=False, force_replace=False, timeout=10)
            
            # bing_image_downloader creates a folder named after the query (e.g. 'e-waste Battery').
            # We need to rename it to just the label ('Battery').
            query_folder = os.path.join(DATASET_DIR, query)
            label_folder = os.path.join(DATASET_DIR, label)
            
            if os.path.exists(query_folder):
                os.rename(query_folder, label_folder)
                
        except Exception as e:
            print(f"Error downloading {label}: {e}")
            
    print("\nDownload complete! You now have real images in the dataset folder.")

if __name__ == "__main__":
    main()
