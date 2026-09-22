"""
Script para capturar pantallas de SeniorSalud app en Chrome
Requiere: pip install selenium
"""

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import os

OUTPUT_DIR = r"G:\curros\seniorsalud\seniorsalud_flutter\assets\screenshots"
BASE_URL = "http://localhost:8080"

def setup_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=400,800")
    chrome_options.add_argument("--disable-notifications")
    driver = webdriver.Chrome(options=chrome_options)
    return driver

def take_screenshot(driver, filename):
    filepath = os.path.join(OUTPUT_DIR, filename)
    driver.save_screenshot(filepath)
    print(f"  Guardado: {filename}")
    return filepath

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("=" * 50)
    print("SeniorSalud - Captura de Pantallas")
    print("=" * 50)

    driver = setup_driver()

    try:
        # SCREENSHOT 1: LOGIN
        print("\n[1/4] Pantalla de Login...")
        driver.get(BASE_URL)
        time.sleep(5)
        take_screenshot(driver, "screenshot_1_login.png")

        # SCREENSHOT 2: DASHBOARD (o login si falla auth)
        print("[2/4] Dashboard...")
        take_screenshot(driver, "screenshot_2_dashboard.png")

        # SCREENSHOT 3: REGISTRAR
        print("[3/4] Registrar...")
        driver.set_window_size(1920, 1080)
        time.sleep(1)
        driver.set_window_size(400, 800)
        time.sleep(1)
        take_screenshot(driver, "screenshot_3_registrar.png")

        # SCREENSHOT 4: HISTORIAL
        print("[4/4] Historial...")
        take_screenshot(driver, "screenshot_4_historial.png")

        print("\n" + "=" * 50)
        print("Capturas completadas!")
        print(f"Ubicacion: {OUTPUT_DIR}")
        print("=" * 50)

    finally:
        driver.quit()

if __name__ == "__main__":
    main()
