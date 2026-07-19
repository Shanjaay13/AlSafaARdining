#!/usr/bin/env python3
import os
import re
import sys
import time
import requests

# Set up paths relative to script location
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MENU_DATA_PATH = os.path.join(BASE_DIR, "lib", "models", "menu_data.dart")
OUTPUT_DIR = os.path.join(BASE_DIR, "assets", "models")

def get_menu_items():
    if not os.path.exists(MENU_DATA_PATH):
        print(f"Error: Could not find menu_data.dart at {MENU_DATA_PATH}")
        sys.exit(1)
        
    with open(MENU_DATA_PATH, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Find all blocks of { ... } representing menu items
    # Using a simple brace matching regex
    item_blocks = re.findall(r'\{([^}]+)\}', content)
    items = []
    for block in item_blocks:
        id_match = re.search(r"'id':\s*'([^']+)'", block)
        name_match = re.search(r"'name':\s*'([^']+)'", block)
        desc_match = re.search(r"'description':\s*\"([^\"]+)\"|'description':\s*'([^']+)'", block)
        category_match = re.search(r"'category':\s*'([^']+)'", block)
        
        if id_match and name_match:
            item_id = id_match.group(1)
            name = name_match.group(1)
            
            # Extract description safely
            description = ""
            if desc_match:
                description = desc_match.group(1) or desc_match.group(2) or ""
                
            category = category_match.group(1) if category_match else ""
            
            items.append({
                'id': item_id,
                'name': name,
                'description': description,
                'category': category
            })
    return items

def build_prompt(name, category, description):
    # Craft high-fidelity text prompt tailored to food category to get optimal 3D output
    base_style = "highly detailed 3D model, realistic food photography style, PBR materials, 8k resolution, photorealistic"
    
    if "Drink" in category:
        prompt = f"A realistic 3D model of Malaysian {name} drink inside a clear glass cup, {description or 'iced sweet drink'}, {base_style}"
    elif "Roti" in category or "Flatbread" in category:
        prompt = f"A realistic 3D model of Malaysian {name} flatbread served on a plate, {description or 'flaky golden brown texture'}, {base_style}"
    elif "Nasi" in category or "Rice" in category:
        prompt = f"A realistic 3D model of a plate of Malaysian {name} dish, {description or 'fried rice with toppings'}, {base_style}"
    elif "Mee" in category or "Noodle" in category:
        prompt = f"A realistic 3D model of a bowl of Malaysian {name} noodle dish, {description or 'spicy noodles'}, {base_style}"
    else:
        prompt = f"A realistic 3D model of Malaysian {name} food dish on a plate, {description or 'traditional cuisine'}, {base_style}"
        
    return prompt

def generate_model(api_key, item):
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    prompt = build_prompt(item['name'], item['category'], item['description'])
    payload = {
        "type": "text_to_model",
        "prompt": prompt
    }
    
    print(f"Submitting task for '{item['name']}'...")
    print(f"Prompt: \"{prompt}\"")
    
    # Submit Task
    response = requests.post("https://api.tripo3d.ai/v2/openapi/task", headers=headers, json=payload)
    if response.status_code != 200:
        print(f"Error submitting task: HTTP {response.status_code} - {response.text}")
        return None
        
    resp_json = response.json()
    if resp_json.get("code") != 0:
        print(f"API Error: {resp_json.get('message')}")
        return None
        
    task_id = resp_json.get("data", {}).get("task_id")
    if not task_id:
        print("Error: No task_id returned from API.")
        return None
        
    print(f"Task submitted successfully! (Task ID: {task_id})")
    
    # Poll Task Status
    while True:
        status_url = f"https://api.tripo3d.ai/v2/openapi/task/{task_id}"
        status_resp = requests.get(status_url, headers=headers)
        if status_resp.status_code != 200:
            print(f"\nError polling status: HTTP {status_resp.status_code}")
            time.sleep(5)
            continue
            
        status_json = status_resp.json()
        if status_json.get("code") != 0:
            print(f"\nAPI Polling Error: {status_json.get('message')}")
            return None
            
        task_data = status_json.get("data", {})
        status = task_data.get("status")
        progress = task_data.get("progress", 0)
        
        if status == "success":
            print(f"\nGeneration succeeded!")
            # Extract GLB URL
            output = task_data.get("output", {})
            glb_url = None
            
            if "glb" in output:
                glb_url = output["glb"]
            elif "model" in output:
                glb_url = output["model"]
            elif "pbr_model_url" in output:
                glb_url = output["pbr_model_url"]
            elif "results" in output and len(output["results"]) > 0:
                glb_url = output["results"][0].get("pbr_model_url")
                
            return glb_url
        elif status == "failed":
            print(f"\nGeneration failed for task {task_id}.")
            return None
        else:
            sys.stdout.write(f"\rStatus: {status} ({progress}%) ...")
            sys.stdout.flush()
            time.sleep(5)

def download_file(url, local_filename):
    print(f"Downloading GLB from {url}...")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
    print(f"Saved to {local_filename}")

def main():
    print("==================================================")
    print("   Tripo3D AI Food Model Generator for Al Safa   ")
    print("==================================================")
    
    # Check/Prompt for API Key
    api_key = os.environ.get("TRIPO_API_KEY")
    if not api_key:
        api_key = input("Enter your Tripo3D API Key: ").strip()
        if not api_key:
            print("Error: API Key is required to generate 3D models.")
            sys.exit(1)
            
    # Load Menu Items
    items = get_menu_items()
    print(f"Loaded {len(items)} active items from menu_data.dart")
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Show items list and let user choose what to generate
    print("\nAvailable items:")
    for idx, item in enumerate(items):
        status = "Already exists" if os.path.exists(os.path.join(OUTPUT_DIR, f"{item['id']}.glb")) else "Pending"
        print(f" [{idx + 1}] {item['name']} ({item['id']}) - [{status}]")
        
    choice = input("\nEnter item index to generate, 'all' to generate pending, or 'q' to quit: ").strip().lower()
    
    if choice == 'q':
        print("Goodbye!")
        sys.exit(0)
        
    targets = []
    if choice == 'all':
        targets = [item for item in items if not os.path.exists(os.path.join(OUTPUT_DIR, f"{item['id']}.glb"))]
        if not targets:
            print("All active items already have 3D models generated in assets/models/!")
            sys.exit(0)
    else:
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(items):
                targets = [items[idx]]
            else:
                print("Invalid index choice.")
                sys.exit(1)
        except ValueError:
            print("Invalid input.")
            sys.exit(1)
            
    print(f"\nStarting generation of {len(targets)} models...")
    success_count = 0
    
    for i, item in enumerate(targets):
        print(f"\n[{i + 1}/{len(targets)}] Processing '{item['name']}' ({item['id']})...")
        local_path = os.path.join(OUTPUT_DIR, f"{item['id']}.glb")
        
        # Check if already exists (safeguard)
        if os.path.exists(local_path):
            print(f"Asset already exists at {local_path}. Skipping.")
            continue
            
        try:
            glb_url = generate_model(api_key, item)
            if glb_url:
                download_file(glb_url, local_path)
                success_count += 1
            else:
                print(f"Failed to generate model for '{item['name']}'")
        except Exception as e:
            print(f"Error processing '{item['name']}': {e}")
            
    print(f"\n==================================================")
    print(f"Done! Successfully generated {success_count} / {len(targets)} models.")
    print("==================================================")

if __name__ == "__main__":
    main()
