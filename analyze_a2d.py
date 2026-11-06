#!/usr/bin/env python3
import struct

# Examine a small .a2d file to understand the format
path = r'C:\Users\pevalcar\AppData\Local\Alea\d3pack\bones\27.a2d'

with open(path, 'rb') as f:
    data = f.read(64)
    
print('=== A2D File Analysis: 27.a2d ===')
print('First 64 bytes (hex):')
print(' '.join(f'{b:02x}' for b in data))
print()

# Check magic
magic = data[:4]
print(f'Magic bytes: {magic}')
expected_magic = b'A2D\x00'
print(f'Expected: A2D null = {expected_magic}')

# Parse header if valid
if magic == expected_magic:
    version = struct.unpack('I', data[4:8])[0]
    width = struct.unpack('I', data[8:12])[0]
    height = struct.unpack('I', data[12:16])[0]
    data_offset = struct.unpack('I', data[16:20])[0]
    
    print(f'Version: {version}')
    print(f'Width: {width}')
    print(f'Height: {height}')
    print(f'Data offset: {data_offset}')
    
    # Read more of the file
    f.seek(0)
    full_data = f.read()
    print(f'File size: {len(full_data)}')
    print(f'Data after header: {len(full_data) - data_offset}')
else:
    print('Magic bytes do not match A2D\\0')
    print('File may use different format or compression')