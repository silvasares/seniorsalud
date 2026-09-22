#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DEFINITIVE byte-level fix based on exact hex analysis of corrupted lines.
"""

import re

def main():
    path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    
    with open(path, 'rb') as f:
        data = f.read()
    
    original_size = len(data)
    
    # ================================================================
    # STEP 1: Replace specific long corrupted emoji byte sequences
    # (Must be done BEFORE the general regex pass)
    # ================================================================
    
    # Warning emoji: ⚠️
    # Hex found: c383c3a2c280c2a6c382c2a1c382c2a0c3adc382c2afc382c2b8c382c28f
    data = data.replace(
        bytes.fromhex('c383c3a2c280c2a6c382c2a1c382c2a0c3adc382c2afc382c2b8c382c28f'),
        '\u26a0\ufe0f'.encode('utf-8')  # ⚠️
    )
    
    # Red circle emoji: 🔴 (ending in c2b4)
    # Hex: c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc382c382c29dc382c2b4
    data = data.replace(
        bytes.fromhex('c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc382c382c29dc382c2b4'),
        '\U0001f534'.encode('utf-8')  # 🔴
    )
    
    # Blue circle emoji: 🔵 (ending in c2b5)
    # Hex: c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc382c382c29dc382c2b5
    data = data.replace(
        bytes.fromhex('c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc382c382c29dc382c2b5'),
        '\U0001f535'.encode('utf-8')  # 🔵
    )
    
    # People emoji: 👥 (line 4042, ending c385c3a2c280c29cc382c2a2)
    # Hex: c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc385c3a2c280c29cc382c2a2
    data = data.replace(
        bytes.fromhex('c3adc382c2b0c383c3a2c280c2a6c382c382c2b8c383c382c2a2c3a2c3a2c280c29ac382c2acc385c3a2c280c29cc382c2a2'),
        '\U0001f465'.encode('utf-8')  # 👥
    )
    
    # Thermometer emoji: 🌡️ (line 3893)
    # Hex: c3b0c382c29fc382c28cc2a1c3afc382c2b8c382c28f
    data = data.replace(
        bytes.fromhex('c3b0c382c29fc382c28cc2a1c3afc382c2b8c382c28f'),
        '\U0001f321\ufe0f'.encode('utf-8')  # 🌡️
    )
    
    # Stethoscope/lungs (line 3896, shorter version without variation selector)
    # Hex: c3b0c382c29fc382c28cc2a1
    data = data.replace(
        bytes.fromhex('c3b0c382c29fc382c28cc2a1'),
        '\U0001f321'.encode('utf-8')  # 🌡 (without variation selector)
    )
    
    # Cross mark with prefix: ❌ (lines 550, 554, 556, 2527)
    # Hex: c29dc383e280a6c3a2e282ace284a2
    data = data.replace(
        bytes.fromhex('c29dc383e280a6c3a2e282ace284a2'),
        '\u274c'.encode('utf-8')  # ❌
    )
    
    # Connection/network emoji (line 552)
    # Hex: c382c29dc383c3a2c280c2a6c3a2c3a2c282c2acc3a2c284c2a2
    data = data.replace(
        bytes.fromhex('c382c29dc383c3a2c280c2a6c3a2c3a2c282c2acc3a2c284c2a2'),
        '\U0001f4e1'.encode('utf-8')  # 📡
    )
    
    # ================================================================
    # STEP 2: General regex to fix double-encoded C2 XX characters
    # Pattern: C3 82 C2 XX -> C2 XX (for °, ¿, ¡, etc.)
    # ================================================================
    data = re.sub(b'\xc3\x82\xc2([\x80-\xbf])', b'\xc2\\1', data)
    
    # Also fix any remaining C3 83 C2 XX -> C3 XX (double-encoded accents)
    data = re.sub(b'\xc3\x83\xc2([\x80-\xbf])', b'\xc3\\1', data)
    
    # Fix C3 83 C3 A2 -> (this is a complex triple-encode, run multiple passes)
    for _ in range(3):
        data = re.sub(b'\xc3\x83\xc2([\x80-\xbf])', b'\xc3\\1', data)
        data = re.sub(b'\xc3\x82\xc2([\x80-\xbf])', b'\xc2\\1', data)
    
    # ================================================================
    # STEP 3: Verify result is valid UTF-8
    # ================================================================
    try:
        text = data.decode('utf-8')
        print("File is valid UTF-8 after fix.")
    except UnicodeDecodeError as e:
        print(f"WARNING: File has UTF-8 errors after fix: {e}")
        # Try to find and show the problematic area
        pos = e.start
        print(f"Problem at byte {pos}: {data[max(0,pos-20):pos+20].hex()}")
    
    with open(path, 'wb') as f:
        f.write(data)
    
    print(f"Original size: {original_size} bytes")
    print(f"Fixed size:    {len(data)} bytes")
    print(f"Bytes saved:   {original_size - len(data)}")
    
    # ================================================================
    # STEP 4: Verify no corruption remains
    # ================================================================
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    issues = []
    for i, line in enumerate(lines, 1):
        # Check for indicators of remaining corruption
        if any(seq in line for seq in ['\xc3\x83', '\xc3\x82', '\xc2\xaf\xc2\xb8', '\xc3\xad\xc2']):
            issues.append(f"  Line {i}: {line.strip()[:120]}")
    
    if issues:
        print(f"\nWARNING: {len(issues)} lines still have potential corruption:")
        for issue in issues[:30]:
            print(issue)
    else:
        print("\n✅ ALL LINES ARE CLEAN! No corruption detected.")


if __name__ == '__main__':
    main()
