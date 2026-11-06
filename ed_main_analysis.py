#!/usr/bin/env python3
import json

# Read characterSelection.json
with open('C:/Users/pevalcar/AppData/Local/Alea/uitk/uxml/characterSelection.json', 'r') as f:
    data = json.load(f)

# Extract the full structure around ed_main
def find_path_with_ed_main(obj, path=''):
    if isinstance(obj, dict):
        name = obj.get('n', '')
        
        if name == 'ed_main':
            print(f"Found ed_main at path: {path}")
            print(f"Type: {obj.get('t')}")
            print(f"Style: {obj.get('s')}")
            print(f"Attributes: {obj.get('a')}")
            print(f"Classes: {obj.get('c')}")
            print()
            return
        
        children = obj.get('k', [])
        for i, child in enumerate(children):
            find_path_with_ed_main(child, f'{path}/{name}[{i}]')
    elif isinstance(obj, list):
        for i, child in enumerate(obj):
            find_path_with_ed_main(child, f'{path}[{i}]')

find_path_with_ed_main(data)

# Now let's look at the parent ctr_entity and ctr_infoMain
def find_ctr_entity(obj, path=''):
    if isinstance(obj, dict):
        name = obj.get('n', '')
        
        if name in ['ctr_entity', 'ctr_infoMain', 'ctr_center']:
            print(f"\n=== {name} ===")
            print(f"Path: {path}")
            print(f"Type: {obj.get('t')}")
            print(f"Style: {obj.get('s')}")
            print(f"Attributes: {obj.get('a')}")
            print(f"Classes: {obj.get('c')}")
            print(f"Has children: {len(obj.get('k', [])) > 0}")
            
            # Show child names
            children = obj.get('k', [])
            if children:
                child_names = []
                for c in children:
                    if isinstance(c, dict):
                        child_names.append(c.get('n', c.get('t', 'unknown')))
                print(f"Children: {child_names}")
        
        children = obj.get('k', [])
        for i, child in enumerate(children):
            find_ctr_entity(child, f'{path}/{name}[{i}]')
    elif isinstance(obj, list):
        for i, child in enumerate(obj):
            find_ctr_entity(child, f'{path}[{i}]')

find_ctr_entity(data)

# Let's also extract the full JSON for the main avatar section
def get_ed_main_parent_structure(obj, depth=0, target_depth=5):
    if depth > target_depth:
        return
    
    if isinstance(obj, dict):
        if obj.get('n') == 'ed_main':
            print("\n=== Parent Structure Around ed_main ===")
            print(json.dumps(obj, indent=2)[:2000])
            return
        
        children = obj.get('k', [])
        for i, child in enumerate(children):
            get_ed_main_parent_structure(child, depth + 1, target_depth)
    elif isinstance(obj, list):
        for i, child in enumerate(obj):
            get_ed_main_parent_structure(child, depth, target_depth)

# Get ctr_entity structure
def find_ctr_entity_full(obj, path=''):
    if isinstance(obj, dict):
        name = obj.get('n', '')
        
        if name == 'ctr_entity':
            print(f"\n=== Full ctr_entity Structure ===")
            print(json.dumps(obj, indent=2))
            return
        
        children = obj.get('k', [])
        for i, child in enumerate(children):
            find_ctr_entity_full(child, f'{path}/{name}[{i}]')
    elif isinstance(obj, list):
        for i, child in enumerate(obj):
            find_ctr_entity_full(child, f'{path}[{i}]')

find_ctr_entity_full(data)