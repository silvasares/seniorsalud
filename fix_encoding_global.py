import os
import re

def fix_string(text):
    """
    Recursively fixes double and triple UTF-8 encoding.
    """
    if not text:
        return text
    
    current = text
    # Try up to 4 levels of nested encoding (just in case)
    for _ in range(4):
        try:
            # We only want to try fixing if we see indicators of corruption
            if any(c in current for c in "ÃÂâðíï"):
                # Candidate for fixing
                candidate = current.encode('latin-1').decode('utf-8')
                # If the candidate is different and doesn't look worse, accept it
                if candidate != current:
                    current = candidate
                else:
                    break
            else:
                break
        except (UnicodeEncodeError, UnicodeDecodeError):
            break
    return current

# Manual mappings for things that the automatic unroller might miss or mangle
MANUAL_MAPPINGS = {
    # Triple/Double encoded emojis and special symbols
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
    "Ã°ÂŸÂšÂ‘": "🚑",
    "Ã°ÂŸÂ“Â£": "📢",
    "Ã°ÂŸÂ“Â…": "📅",
    "Ã°ÂŸÂ’Â¬": "💬",
    "Ã°ÂŸÂ’Â": "💪", # or similar
    "Ã°ÂŸÂšÂª": "🚪",
    "Ã°ÂŸÂ—Â³": "🗳️",
    "Ã°ÂŸÂ”Â": "🔍",
    "Ã°ÂŸÂ—Â’": "🗒️",
    
    # Complex sequences
    "Ãƒâ€¦Ã‚¡Â íÂ¯Â¸Â": "⚠️",
    "Ãƒâ€¦Ã‚¡Â ": "⚠️",
    "íÂ°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Â´": "🔴",
    "íÂ°Ãƒâ€¦Ã‚Â¸Â Â¥": "📍",
    "íÂ°Ãƒâ€¦Ã‚Â¸Â’Â¡": "💡",
    "íÂ°Ãƒâ€¦Ã‚Â¸ÂšÂ¨": "🚨",
    "íÂ°Ãƒâ€¦Ã‚Â¸ÂšÂ‘": "🚑",
    "íÂ°Ãƒâ€¦Ã‚Â¸Â“ÂŠ": "📊",
    
    # Degenerate characters
    "Ã‚Â°C": "°C",
    "ÃƒÂ‚Ã‚Â°C": "°C",
    "Ã‚Â¿": "¿",
    "Ã‚Â¡": "¡",
    "ÃƒÂ‚Ã‚Â¿": "¿",
    "ÃƒÂ‚Ã‚Â¡": "¡",
    
    # Others
    "Ã¢Â€Â¦": "…",
    "Ã¢Â„Â¢": "™",
    "Ã¢Â‚Â¬": "€",
    "Ã…Â“": "œ",
    "Ã…Â¡": "š",
}

def clean_file(file_path):
    print(f"Cleaning: {file_path}")
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception as e:
        print(f"  Error reading {file_path}: {e}")
        return

    new_lines = []
    for line in lines:
        # 1. Apply manual mappings first
        for old, new in MANUAL_MAPPINGS.items():
            line = line.replace(old, new)
        
        # 2. Identify strings in quotes and try to fix them individually
        # This is safer than fixing the whole line
        def replacer(match):
            return match.group(1) + fix_string(match.group(2)) + match.group(3)
        
        # Match single or double quoted strings
        # (Handling escaped quotes is omitted for simplicity as it's unlikely to be the cause of corruption)
        line = re.sub(r'([\'"])(.*?)([\'"])', replacer, line)
        
        # 3. Also fix comments
        if "//" in line:
            parts = line.split("//", 1)
            line = parts[0] + "//" + fix_string(parts[1])
        
        new_lines.append(line)

    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

def main():
    root_dir = r"g:\curros\seniorsalud\seniorsalud_flutter\lib"
    for root, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart"):
                clean_file(os.path.join(root, file))
    
    # Also clean some SQL files just in case
    for file in [r"g:\curros\seniorsalud\seniorsalud_flutter\setup_database.sql", 
                 r"g:\curros\seniorsalud\seniorsalud_flutter\fix_appointments.sql"]:
        if os.path.exists(file):
            clean_file(file)

    print("\nGlobal cleanup complete.")

if __name__ == "__main__":
    main()
