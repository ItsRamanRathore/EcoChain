import os
import requests
from duckduckgo_search import DDGS
from concurrent.futures import ThreadPoolExecutor

LABELS = ["Battery", "Cable", "CRT", "LCD", "Mixed", "Motor", "PCB", "Plastic"]
DATASET_DIR = "dataset"
IMAGES_PER_CLASS = 30

def download_image(url, save_path):
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            with open(save_path, 'wb') as f:
                f.write(response.content)
            return True
    except Exception:
        pass
    return False

def scrape_category(label):
    query = f"e-waste {label}"
    label_dir = os.path.join(DATASET_DIR, label)
    if not os.path.exists(label_dir):
        os.makedirs(label_dir)
        
    print(f"Searching images for {label}...")
    try:
        results = DDGS().images(
            keywords=query,
            region="wt-wt",
            safesearch="off",
            size=None,
            color=None,
            type_image=None,
            layout=None,
            license_image=None,
            max_results=IMAGES_PER_CLASS + 10
        )
    except Exception as e:
        print(f"Error searching {label}: {e}")
        return

    count = 0
    urls = [r.get("image") for r in results if r.get("image")]
    
    for url in urls:
        if count >= IMAGES_PER_CLASS:
            break
        ext = url.split('.')[-1][:3].lower()
        if ext not in ['jpg', 'png', 'jpe']:
            ext = 'jpg'
        
        save_path = os.path.join(label_dir, f"{count}.{ext}")
        if download_image(url, save_path):
            count += 1
    
    print(f"Downloaded {count} images for {label}")

def main():
    if not os.path.exists(DATASET_DIR):
        os.makedirs(DATASET_DIR)
        
    print("Starting dataset download from Web...")
    with ThreadPoolExecutor(max_workers=4) as executor:
        executor.map(scrape_category, LABELS)
        
    print("Download complete!")

if __name__ == "__main__":
    main()
