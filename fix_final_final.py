import os
import re

def main():
    file_path = r"g:\curros\seniorsalud\seniorsalud_flutter\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Define line-specific fixes for stubborn sequences
    # Using regex to match the corrupted parts regardless of exact encoding representation
    
    # Line 1452: Usuario • ...
    lines[1451] = re.sub(r"Usuario .*? años", "Usuario • ${userAge ?? '---'} años", lines[1451])
    
    # Line 1497-1498: pending/rejected
    lines[1496] = "      case 'pending': return ' ⏳ Pendiente';\n"
    lines[1497] = "      case 'rejected': return ' ❌ Inactivo';\n"
    
    # Line 1546-1547: BP status
    lines[1545] = "                ' ⚠️ Elevada: 120-139 / 80-89 mmHg',\n"
    lines[1546] = "                ' 🔴 Alta: 140/90 mmHg o más',\n"
    
    # Line 1562-1563: Heart rate status
    lines[1561] = "                ' ⚠️ Bajo: Menos de 60 lpm',\n"
    lines[1562] = "                ' 🔴 Alto: Más de 100 lpm',\n"
    
    # Line 1578-1579: Glucose status
    lines[1577] = "                ' ⚠️ Prediabetes: 100-125 mg/dL',\n"
    lines[1578] = "                ' 🔴 Diabetes: 126 mg/dL o más',\n"
    
    # Line 1608-1610: Temperature status
    lines[1607] = "                ' ✅ Normal: 36.1°C - 37.2°C',\n"
    lines[1608] = "                ' ⚠️ Febrícula: 37.3°C - 38.0°C',\n"
    lines[1609] = "                ' 🔴 Fiebre: 38.1°C o más',\n"
    
    # Line 1643-1647: Emergency items
    lines[1642] = "                  _buildEmergencyItem('🚑 Emergencias médicas', '112'),\n"
    lines[1644] = "                  _buildEmergencyItem('🚨 Tu médico de cabecera', 'Llama a tu centro de salud'),\n"
    lines[1646] = "                  _buildEmergencyItem('📍 Centro de salud más cercano', 'Acude si tienes síntomas graves'),\n"

    # General pass for any remaining Ã or Â that look like corruption
    # But only in strings
    for i in range(len(lines)):
        # Fix the °C which is very common
        lines[i] = lines[i].replace("Ã‚°C", "°C").replace("ÃƒÂ‚Ã‚Â°C", "°C").replace("?C", "°C")
        # Fix common bullet point
        lines[i] = lines[i].replace("Ã¢Â€Â¢", "•")
        # Fix checkmark
        lines[i] = lines[i].replace("Ã¢ÂœÂ…", "✅").replace("Ã¢???", "✅")

    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(lines)
    
    print("Definitive fix applied to lib/main.dart")

if __name__ == "__main__":
    main()
