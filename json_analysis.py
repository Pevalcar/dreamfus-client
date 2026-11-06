#!/usr/bin/env python3
import json
import sys

# Read and parse the characterSelection.json
with open('C:/Users/pevalcar/AppData/Local/Alea/uitk/uxml/characterSelection.json', 'r') as f:
    data = json.load(f)

# Extract elements with their IDs and key attributes
found_elements = []

def extract_elements(obj, path=''):
    if isinstance(obj, dict):
        name = obj.get('n', '')
        elem_type = obj.get('t', '')
        
        # Look for ed_main (AnimatedDisplayerComponent)
        if name == 'ed_main':
            found_elements.append({
                'path': path,
                'type': elem_type,
                'name': name,
                'style': obj.get('s', ''),
                'attributes': obj.get('a', {})
            })
        
        # Look for character slots
        if 'slot' in name.lower() or 'character' in name.lower():
            found_elements.append({
                'path': path,
                'type': elem_type,
                'name': name,
                'style': obj.get('s', ''),
                'attributes': obj.get('a', {})
            })
            
        # Look for CTR_entity or ctr_infoMain
        if 'ctr_' in name and ('entity' in name.lower() or 'info' in name.lower()):
            found_elements.append({
                'path': path,
                'type': elem_type,
                'name': name,
                'style': obj.get('s', ''),
                'attributes': obj.get('a', {})
            })
        
        # Recurse into children
        children = obj.get('k', [])
        for i, child in enumerate(children):
            extract_elements(child, f'{path}/{name}[{i}]')

extract_elements(data)

print('=== Key Elements Found in characterSelection.json ===')
for elem in found_elements:
    print(f"\nName: {elem['name']}")
    print(f"Type: {elem['type']}")
    print(f"Path: {elem['path']}")
    if elem['style']:
        if len(elem['style']) > 100:
            print(f"Style: {elem['style'][:100]}...")
        else:
            print(f"Style: {elem['style']}")
    if elem['attributes']:
        print(f"Attributes: {elem['attributes']}")