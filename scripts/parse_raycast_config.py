#!/usr/bin/env python3
"""Parse Raycast .rayconfig export and generate bindings.json for hyper_key_overlay.

Usage:
    python3 parse_raycast_config.py <rayconfig_file> <password>

The output is written to modules/hyper_key_overlay/bindings.json
"""

import gzip
import json
import os
import subprocess
import sys

# macOS keycode -> key name
KEYCODE_MAP = {
    0: 'a', 1: 's', 2: 'd', 3: 'f', 4: 'h', 5: 'g', 6: 'z', 7: 'x',
    8: 'c', 9: 'v', 11: 'b', 12: 'q', 13: 'w', 14: 'e', 15: 'r',
    16: 'y', 17: 't', 18: '1', 19: '2', 20: '3', 21: '4', 22: '6',
    23: '5', 24: '=', 25: '9', 26: '7', 27: '-', 28: '8', 29: '0',
    30: ']', 31: 'o', 32: 'u', 33: '[', 34: 'i', 35: 'p', 37: 'l',
    38: 'j', 39: ';', 40: 'k', 41: "'", 43: ',', 44: '/', 45: 'n',
    46: 'm', 47: '.', 49: 'space', 50: '`',
}


def decrypt_rayconfig(filepath, password):
    """Decrypt a .rayconfig file (AES-256-CBC, no salt, 16-byte header, gzipped JSON)."""
    cmd = ['openssl', 'enc', '-d', '-aes-256-cbc', '-nosalt', '-in', filepath, '-k', password]
    result = subprocess.run(cmd, capture_output=True)
    if result.returncode != 0:
        # Try with -md md5 for newer OpenSSL
        cmd.extend(['-md', 'md5'])
        result = subprocess.run(cmd, capture_output=True)
    if result.returncode != 0:
        print("Error: Failed to decrypt file", file=sys.stderr)
        sys.exit(1)
    # Skip 16-byte header, then decompress
    return json.loads(gzip.decompress(result.stdout[16:]))


def extract_bindings(data):
    """Extract Hyper key bindings from Raycast config data."""
    items = data.get('builtin_package_rootSearch', {}).get('rootSearch', [])
    bindings = {}

    for item in items:
        hotkey = item.get('hotkey', '')
        if 'Shift-Control-Option-Command' not in hotkey:
            continue

        keycode = int(hotkey.split('-')[-1])
        key = KEYCODE_MAP.get(keycode)
        if not key:
            continue

        item_type = item.get('type', '')
        path = item.get('path', '')
        key_id = item.get('key', '')
        binding = {}

        if item_type == 'systemApp' and path:
            app_name = path.rstrip('/').split('/')[-1].replace('.app', '')
            binding['label'] = app_name
            binding['icon'] = key_id  # bundle ID
            if '~' in path or 'Chrome Apps' in path:
                binding['appPath'] = path
        elif item_type in ('command', 'nodeCommand'):
            name = key_id.replace('builtin_command_', '').replace('extension_', '').split('.')[0]
            binding['label'] = name
        elif item_type == 'quicklink':
            binding['label'] = 'Slack Ch' if 'slack://' in path else 'Link'
        elif item_type == 'aiCommand':
            binding['label'] = 'AI Cmd'
        else:
            binding['label'] = key_id[:20]

        bindings[key] = binding

    return bindings


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <rayconfig_file> <password>")
        sys.exit(1)

    data = decrypt_rayconfig(sys.argv[1], sys.argv[2])
    bindings = extract_bindings(data)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, '..', 'modules', 'hyper_key_overlay', 'bindings.json')
    output_path = os.path.normpath(output_path)

    with open(output_path, 'w') as f:
        json.dump(bindings, f, indent=2, ensure_ascii=False)

    print(f"Written {len(bindings)} bindings to {output_path}")
    for key in sorted(bindings):
        b = bindings[key]
        print(f"  Hyper+{key.upper():5s} => {b['label']}")


if __name__ == '__main__':
    main()
