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


# Friendly label mappings for builtin commands and known extensions
LABEL_MAP = {
    'calendar_schedule': 'Calendar',
    'raycastNotes_toggle': 'Notes',
    'searchMenuItems': 'Menu Search',
    'toggleSystemAppearance': 'Dark Mode',
    'translate': 'Translate',
    'snippets_search': 'Snippets',
    'confetti': 'Confetti',
    'calculator': 'Calculator',
    'clipboard_history': 'Clipboard',
    'windowManagement': 'Windows',
}

EXTENSION_LABEL_MAP = {
    'do-not-disturb': 'DND',
    'google-chrome': 'Tab Search',
    'korean-spell-checker': 'Spell Check',
    'youtube-shorts-to-normal-video-page': 'YT Shorts',
    'color-picker': 'Color Picker',
    'brew': 'Homebrew',
    'github': 'GitHub',
    'linear': 'Linear',
    'slack-status': 'Slack Status',
}

# Friendly app name overrides
APP_LABEL_MAP = {
    'Google Chrome': 'Chrome',
    'zoom.us': 'Zoom',
    'Screen Sharing': 'Screen Share',
    'YouTube Music': 'YT Music',
}


def _clean_app_label(app_name):
    """Clean up app name for display."""
    return APP_LABEL_MAP.get(app_name, app_name)


def _clean_command_label(key_id):
    """Generate a friendly label from a command/extension key ID."""
    # Check builtin commands
    name = key_id.replace('builtin_command_', '')
    if name in LABEL_MAP:
        return LABEL_MAP[name]

    # Check extensions
    ext_name = key_id.replace('extension_', '').split('.')[0]
    if ext_name in EXTENSION_LABEL_MAP:
        return EXTENSION_LABEL_MAP[ext_name]

    # Fallback: clean up the name
    name = ext_name.replace('-', ' ').replace('_', ' ').title()
    # Truncate if too long
    if len(name) > 12:
        name = name[:11] + '…'
    return name


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
            binding['label'] = _clean_app_label(app_name)
            binding['icon'] = key_id  # bundle ID
            if '~' in path or 'Chrome Apps' in path:
                binding['appPath'] = path
        elif item_type in ('command', 'nodeCommand'):
            binding['label'] = _clean_command_label(key_id)
        elif item_type == 'quicklink':
            if 'slack://' in path:
                binding['label'] = 'Slack Ch'
            elif 'notion://' in path or 'notion.so' in path:
                binding['label'] = 'Notion'
            elif 'linear://' in path or 'linear.app' in path:
                binding['label'] = 'Linear'
            else:
                binding['label'] = 'Link'
        elif item_type == 'aiCommand':
            binding['label'] = 'AI Cmd'
        else:
            binding['label'] = key_id[:12]

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
