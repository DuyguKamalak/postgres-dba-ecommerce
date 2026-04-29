import os
import subprocess
import sys

DATASET = "olistbr/brazilian-ecommerce"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "raw")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"Downloading dataset to {OUTPUT_DIR} ...")
    result = subprocess.run(
        ["kaggle", "datasets", "download", "-d", DATASET, "-p", OUTPUT_DIR, "--unzip"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print("ERROR:", result.stderr)
        sys.exit(1)
    print("Done. Files:")
    for f in os.listdir(OUTPUT_DIR):
        print(f"  {f}")

if __name__ == "__main__":
    main()
