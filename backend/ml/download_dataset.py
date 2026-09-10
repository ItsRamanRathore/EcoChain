from bing_image_downloader import downloader
import os

categories = {
    'PCB':      'printed circuit board ewaste',
    'Cable':    'copper wire cable scrap',
    'Battery':  'lithium battery ewaste',
    'LCD':      'LCD screen panel broken',
    'CRT':      'CRT monitor old television',
    'Motor':    'electric motor scrap',
    'Plastic':  'electronic plastic waste',
    'Mixed':    'mixed electronic waste scrap',
}

for label, query in categories.items():
    downloader.download(
        query,
        limit=60,
        output_dir='dataset',
        adult_filter_off=True,
        force_replace=False,
        timeout=10,
        verbose=False
    )
    # Rename downloaded folder to match label
    old_dir = os.path.join('dataset', query)
    new_dir = os.path.join('dataset', label)
    if os.path.exists(old_dir):
        if not os.path.exists(new_dir):
            os.rename(old_dir, new_dir)
        else:
            # If the destination already exists, just remove the newly created directory
            import shutil
            shutil.rmtree(old_dir, ignore_errors=True)
