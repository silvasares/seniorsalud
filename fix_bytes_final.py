import os
import re

def fix_bytes(data):
    # Pattern for triple encoding: C3 83 C2 83 C2 [XX]
    # where [XX] is the second byte of a UTF-8 character (A1, B3, etc.)
    
    # Also handle double encoding: C3 83 C2 [XX]
    
    # We'll use regex on bytes
    # Double encoding
    data = re.sub(b'\xc3\x83\xc2([\x80-\xbf])', b'\xc3\\1', data)
    
    # Triple encoding (if it survived the first pass, it might be nested)
    # Actually, we should do it multiple times
    for _ in range(3):
        data = re.sub(b'\xc3\x83\xc2([\x80-\xbf])', b'\xc3\\1', data)

    # Specific fixes for Emojis which have different patterns (often 3-byte UTF-8)
    # ✅ (E2 9C 85)
    # Double: C3 A2 C2 9C C2 85 (if interpreted as latin-1)
    # Triple: C3 83 C2 A2 C3 82 C2 9C C3 82 C2 85
    
    # Since emojis are harder to regex, we'll do manual byte replacements for the most common ones
    emoji_replacements = [
        (b'\xc3\xa2\xc2\x9c\xc2\x85', b'\xe2\x9c\x85'), # ✅
        (b'\xc3\x83\xc2\xa2\xc3\x82\xc2\x9c\xc3\x82\xc2\x85', b'\xe2\x9c\x85'), # ✅ (triple)
        (b'\xc3\xa2\xc2\x80\xc2\xa2', b'\xe2\x80\xa2'), # •
    ]
    
    for old, new in emoji_replacements:
        data = data.replace(old, new)
        
    return data

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    with open(file_path, "rb") as f:
        data = f.read()
    
    fixed_data = fix_bytes(data)
    
    # Special case for the "reciente" line we found
    # c3 83 c2 83 c2 a1 -> c3 a1 (á)
    fixed_data = fixed_data.replace(b'\xc3\x83\xc2\x83\xc2\xa1', b'\xc3\xa1')
    
    with open(file_path, "wb") as f:
        f.write(fixed_data)
    
    print("Definitive byte-level fix complete.")

if __name__ == "__main__":
    main()
