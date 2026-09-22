import os

def fix_bytes(data):
    # Common triple-encoded sequences in bytes
    # á: C3 A1 
    # Double encoded: C3 83 C2 A1 (Ã¡)
    # Triple encoded: C3 83 C6 92 C2 A1 (Ãƒ¡)
    
    # We'll do replacements on bytes to avoid encoding issues
    replacements = [
        (b'\xc3\x83\xc6\x92\xc2\xa1', b'\xc3\xa1'), # á (triple)
        (b'\xc3\x83\xc6\x92\xc2\xa9', b'\xc3\xa9'), # é (triple)
        (b'\xc3\x83\xc6\x92\xc2\xad', b'\xc3\xad'), # í (triple)
        (b'\xc3\x83\xc6\x92\xc2\xb3', b'\xc3\xb3'), # ó (triple)
        (b'\xc3\x83\xc6\x92\xc2\xba', b'\xc3\xba'), # ú (triple)
        (b'\xc3\x83\xc6\x92\xc2\xb1', b'\xc3\xb1'), # ñ (triple)
        
        (b'\xc3\x83\xc2\xa1', b'\xc3\xa1'), # á (double)
        (b'\xc3\x83\xc2\xa9', b'\xc3\xa9'), # é (double)
        (b'\xc3\x83\xc2\xad', b'\xc3\xad'), # í (double)
        (b'\xc3\x83\xc2\xb3', b'\xc3\xb3'), # ó (double)
        (b'\xc3\x83\xc2\xba', b'\xc3\xba'), # ú (double)
        (b'\xc3\x83\xc2\xb1', b'\xc3\xb1'), # ñ (double)
        
        # Upper case
        (b'\xc3\x83\xc6\x92\xe2\x80\x9c', b'\xc3\x93'), # Ó
        (b'\xc3\x83\xe2\x80\x9c', b'\xc3\x93'), # Ó (double)
        
        # Emojis and others
        (b'\xc3\xa2\xc2\x9c\xc2\x85', b'\xe2\x9c\x85'), # ✅
        (b'\xc3\xa2\xc2\x80\xc2\xa2', b'\xe2\x80\xa2'), # •
    ]
    
    for old, new in replacements:
        data = data.replace(old, new)
    
    return data

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    with open(file_path, "rb") as f:
        data = f.read()
    
    fixed_data = fix_bytes(data)
    
    with open(file_path, "wb") as f:
        f.write(fixed_data)
    
    print("Byte-level fix complete for lib/main.dart")

if __name__ == "__main__":
    main()
