import sys

file_path = "lib/main.dart"
try:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Define replacements
    replacements = {
        "ÃƒÆ’Ã‚Â³": "ó",
        "ÃƒÆ’Ã‚Â±": "ñ",
        "ÃƒÆ’Ã‚Â¡": "á",
        "ÃƒÆ’Ã‚Â©": "é",
        "ÃƒÆ’Ã‚Â­": "í",
        "ÃƒÂ­": "í",
        "AÃ±ade": "Añade",
        "tensiÃ³n": "tensión",
        "MedicaciÃ³n": "Medicación",
        "estadÃ­sticas": "estadísticas"
    }

    for old, new in replacements.items():
        content = content.replace(old, new)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Fixed accents successfully.")
except Exception as e:
    print(f"Error: {e}")
