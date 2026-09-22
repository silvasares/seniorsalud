import os

def fix_string(text):
    """
    Attempts to fix multiple UTF-8 encodings by repeatedly encoding to latin-1 
    and decoding from utf-8.
    """
    if not text:
        return text
    
    current = text
    for _ in range(3): # Try up to 3 levels of nesting
        try:
            # Check if it looks like it's encoded
            # If it contains Ã or other common indicators
            if any(c in current for c in "ÃÂâ"):
                candidate = current.encode('latin-1').decode('utf-8')
                current = candidate
            else:
                break
        except (UnicodeEncodeError, UnicodeDecodeError):
            break
    return current

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    fixed_lines = []
    for line in lines:
        # We only want to fix strings inside quotes or comments
        # But for simplicity, we can try to fix the whole line if it contains the corruption symbols
        if "Ã" in line or "Â" in line:
            # Special case for some emojis that might not follow the simple pattern
            replacements = {
                "Ã¢ÂœÂ…": "✅",
                "Ã¢Â€Â¢": "•",
                "Ã°ÂŸÂ©Âº": "🩺",
                "Ã°ÂŸÂ’Â¡": "💡",
                "Ã°ÂŸÂšÂ¨": "🚨",
                "Ã°ÂŸÂ”Â”": "🔔",
                "Ã°ÂŸÂ“ÂŠ": "📊",
                "Ã°ÂŸÂ“Â‹": "📋",
                "Ã°ÂŸÂ’Â¬": "💬",
                "Ã°ÂŸÂ’Â💊": "💊",
                "Ã°ÂŸÂ’Â°": "💰",
                "Ã°ÂŸÂšÂ": "🚑",
                "íÂ°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Â´": "🔴", # This looks like a red circle or similar
                "íÂ°Ãƒâ€¦Ã‚Â¸Â Â¥": "📍",
                "Ãƒâ€¦Ã‚¡Â íÂ¯Â¸Â": "⚠️",
                "Ã‚Â°C": "°C",
                "ÃƒÂ‚Ã‚Â°C": "°C",
            }
            
            for old, new in replacements.items():
                line = line.replace(old, new)
            
            # Now try the general fix for remaining characters
            fixed_line = fix_string(line)
            fixed_lines.append(fixed_line)
        else:
            fixed_lines.append(line)

    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(fixed_lines)
    
    print("Cleanup complete for lib/main.dart")

if __name__ == "__main__":
    main()
