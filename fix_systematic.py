import os

def fix_unroll(text):
    """
    Tries to unroll multi-encoded UTF-8 strings.
    """
    try:
        # If it looks like double/triple encoded, unroll it
        # Check for typical start bytes of multi-encoded chars
        if "Ã" in text or "Â" in text or "â" in text or "ð" in text:
            curr = text
            for _ in range(4):
                try:
                    # Only proceed if there are high-bit characters that look like corruption
                    if any(c in curr for c in "ÃÂâðíï"):
                        next_val = curr.encode('latin-1').decode('utf-8')
                        if next_val != curr:
                            curr = next_val
                        else:
                            break
                    else:
                        break
                except:
                    break
            return curr
    except:
        pass
    return text

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        fixed = fix_unroll(line)
        # Apply some manual replacements for known issues that unrolling might miss
        replacements = {
            "Ã‚°C": "°C",
            "ÃƒÂ‚Ã‚Â°C": "°C",
            "Ã¢ÂœÂ…": "✅",
            "Ã¢Â€Â¢": "•",
            "ðŸš‘": "🚑",
            "Ã°ÂŸÂ©Âº": "🩺",
            "Ã°ÂŸÂ’Â¡": "💡",
            "Ã°ÂŸÂšÂ¨": "🚨",
            "Ã°ÂŸÂ”Â”": "🔔",
            "Ã°ÂŸÂ“ÂŠ": "📊",
            "Ã°ÂŸÂ“Â‹": "📋",
            "Ã°ÂŸÂ’Â¬": "💬",
            "Ã°ÂŸÂ’Â💊": "💊",
            "Ã°ÂŸÂ’Â°": "💰",
            "Ã¢Â€Â¦": "…",
        }
        for old, new in replacements.items():
            fixed = fixed.replace(old, new)
        
        new_lines.append(fixed)

    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    
    print("Full systematic cleanup of lib/main.dart complete.")

if __name__ == "__main__":
    main()
