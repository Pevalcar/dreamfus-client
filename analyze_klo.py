#!/usr/bin/env python3
import struct

binary_path = r'C:\Users\pevalcar\AppData\Local\Alea\alea-client.exe'

with open(binary_path, 'rb') as f:
    # Seek to KLO position (18,506,840)
    f.seek(18506840)
    
    # Read first 512 bytes at KLO position
    data = f.read(512)
    
    print('=== KLO Module Analysis at position 18,506,840 ===')
    print()
    print('First 64 bytes (hex):')
    print(' '.join(f'{b:02x}' for b in data[:64]))
    print()
    
    # Check for WASM magic number
    if data[:4] == b'\x00asm':
        print('WASM magic number detected!')
        print(f'Version: {struct.unpack("I", data[4:8])[0]}')
    elif data[:3] == b'KLO':
        print('KLO marker detected at start')
    elif data[:3] == b'\xf0\x84D':
        print('Extended KLO marker detected (0xf0 0x84 0x44)')
    else:
        print(f'First bytes: {data[:8]}')
        print(f'ASCII: {data[:8].decode("latin-1")}')
    
    # Look for function names or strings
    print()
    print('=== Possible strings in first 256 bytes ===')
    strings = []
    current_string = b''
    for b in data[:256]:
        if 32 <= b <= 126:
            current_string += bytes([b])
        else:
            if len(current_string) >= 4:
                strings.append(current_string.decode('ascii'))
            current_string = b''
    if len(current_string) >= 4:
        strings.append(current_string.decode('ascii'))
    
    for s in strings:
        print(f'  "{s}"')