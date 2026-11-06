#!/usr/bin/env python3
"""
convert_a2d.py - Pre-procesador para archivos A2D.Z
Convierten archivos A2D.Z (deflate) a WebP para uso en Godot

Uso:
    python convert_a2d.py input.a2d output.webp [--json]
"""

import sys
import struct
import zlib
from pathlib import Path


def read_varint(data: bytes, offset: int) -> tuple:
    """Lee un VarInt de 3 bytes (como en el formato Dofus)"""
    result = 0
    shift = 0
    pos = offset
    
    while pos < len(data):
        byte = data[pos]
        pos += 1
        result |= ((byte & 0x7F) << shift)
        if (byte & 0x80) == 0:
            break
        shift += 7
        if shift > 28:
            raise ValueError("VarInt too long")
    
    return result, pos - offset


def parse_a2dz(data: bytes) -> dict:
    """
    Parse un archivo A2DZ
    Retorna información sobre sprites e imágenes
    """
    if len(data) < 8:
        raise ValueError("Archivo demasiado pequeño para A2DZ")
    
    # Verificar magic "A2DZ"
    if data[:4] != b'A2DZ':
        raise ValueError(f"Magic inválido: {data[:4]}")
    
    version = data[4]
    
    # Descomprimir usando raw deflate (skip zlib header)
    # Los datos A2DZ usan raw deflate, no zlib estándar
    compressed = data[8:]
    
    try:
        # Intentar descompresión raw deflate
        # zlib.decompress puede manejar raw deflate con wbits=-15
        decompressed = zlib.decompress(compressed, -15)
    except zlib.error as e:
        # Intentar con zlib estándar
        try:
            decompressed = zlib.decompress(compressed)
        except zlib.error:
            raise ValueError(f"Error de descompresión: {e}")
    
    return {
        'version': version,
        'decompressed': decompressed,
    }


def extract_webp_images(data: bytes) -> list:
    """
    Busca y extrae imágenes WebP de datos binarios
    """
    images = []
    offset = 8  # Saltar encabezado A2D1
    
    while offset + 12 <= len(data):
        # Buscar firma RIFF...WEBP
        if (data[offset:offset+4] == b'RIFF' and 
            offset + 8 < len(data) and 
            data[offset+8:offset+12] == b'WEBP'):
            
            riff_size = struct.unpack('<I', data[offset+4:offset+8])[0]
            total_size = 12 + riff_size
            
            if offset + total_size <= len(data):
                image_data = data[offset:offset+total_size]
                images.append({
                    'data': image_data,
                    'offset': offset,
                    'size': total_size,
                })
                offset += total_size
            else:
                offset += 1
        else:
            offset += 1
    
    return images


def main():
    if len(sys.argv) < 3:
        print("Uso: python convert_a2d.py input.a2d output.webp [--json]")
        sys.exit(1)
    
    input_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    output_json = '--json' in sys.argv
    
    if not input_path.exists():
        print(f"Error: Archivo no existe: {input_path}")
        sys.exit(1)
    
    # Leer archivo
    with open(input_path, 'rb') as f:
        data = f.read()
    
    print(f"Leyendo: {input_path} ({len(data)} bytes)")
    
    # Parsear A2DZ
    result = parse_a2dz(data)
    print(f"Versión A2DZ: {result['version']}")
    
    # Extraer imágenes WebP
    images = extract_webp_images(result['decompressed'])
    print(f"Encontradas {len(images)} imágenes WebP")
    
    if images:
        # Guardar primera imagen como WebP
        with open(output_path, 'wb') as f:
            f.write(images[0]['data'])
        print(f"Guardado: {output_path}")
    
    if output_json:
        import json
        json_result = {
            'input_file': str(input_path),
            'version': result['version'],
            'output_file': str(output_path),
            'images': [
                {
                    'offset': img['offset'],
                    'size': img['size'],
                }
                for img in images
            ]
        }
        print(json.dumps(json_result, indent=2))


if __name__ == '__main__':
    main()