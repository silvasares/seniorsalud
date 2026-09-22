import os

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Broad replacements for triple and double encoded Spanish characters
    # These cover the most common patterns seen in the file
    replacements = {
        "ÃƒÂ¡": "á", "ÃƒÂ©": "é", "ÃƒÂ­": "í", "ÃƒÂ³": "ó", "ÃƒÂº": "ú", "ÃƒÂ±": "ñ",
        "ÃƒÂ": "í", # Sometimes í is cut off
        "ÃƒÂ“": "Ó", "ÃƒÂ‰": "É", "ÃƒÂ¡": "á",
        "Ã¡": "á", "Ã©": "é", "Ã­": "í", "Ã³": "ó", "Ãº": "ú", "Ã±": "ñ",
        "Ã“": "Ó", "Ã‰": "É",
        "Ãƒ¡": "á", "Ãƒ©": "é", "Ãƒ­": "í", "Ãƒ³": "ó", "Ãƒº": "ú", "Ãƒ±": "ñ", # No Â variant
        "Ãƒ“": "Ó",
        "Ã‚Â°C": "°C", "Ã‚°C": "°C", "ÃƒÂ‚Ã‚Â°C": "°C",
        "Ã¢ÂœÂ…": "✅", "Ã¢Â€Â¢": "•", "ðŸš‘": "🚑",
        "Ãƒâ€¦Ã‚¡Â íÂ¯Â¸Â": "⚠️", "Ãƒâ€¦Ã‚¡Â ": "⚠️",
        "íÂ°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â Â´": "🔴",
        "íÂ°Ãƒâ€¦Ã‚Â¸ÃƒÂ¢Ã¢â€šÂ¬Ã‹Å“Â¨": "🚨",
        "íÂ°Ãƒâ€¦Ã‚Â¸Â Â¥": "📍",
        "Ã¢ÂœÂ…": "✅",
    }

    for old, new in replacements.items():
        content = content.replace(old, new)
    
    # Additional cleanup for things like 'mÃƒ¡s' -> 'más'
    content = content.replace("mÃƒ¡s", "más")
    content = content.replace("mÃ¡s", "más")
    content = content.replace(" sesiÃƒÂ³n", " sesión")
    content = content.replace(" sesiÃ³n", " sesión")
    content = content.replace(" mÃƒ¡s", " más")
    content = content.replace(" mÃ¡s", " más")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    
    print("Brute-force cleanup of lib/main.dart complete.")

if __name__ == "__main__":
    main()
