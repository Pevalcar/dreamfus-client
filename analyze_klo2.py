#!/usr/bin/env python3
import struct

binary_path = r'C:\Users\pevalcar\AppData\Local\Alea\alea-client.exe'

with open(binary_path, 'rb') as f:
    # Read larger section around KLO
    f.seek(18506800)
    data = f.read(2000)
    
    # Find all ASCII strings >= 8 chars
    print('=== Strings found around KLO position ===')
    strings = []
    current_string = b''
    for i, b in enumerate(data):
        if 32 <= b <= 126:
            current_string += bytes([b])
        else:
            if len(current_string) >= 8:
                strings.append((i - len(current_string), current_string.decode('ascii', errors='ignore')))
            current_string = b''
    
    # Sort by position
    strings.sort()
    for pos, s in strings[:30]:
        print(f'  Offset {pos + 18506800}: "{s}"')