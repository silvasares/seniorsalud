# Guía para Capturas de Pantalla - SeniorSalud

## Requisitos Google Play Store

- **Resolución mínima:** 1280x720 px (mínimo 2 imágenes)
- **Máximo:** 8 imágenes por idioma
- **Formato:** JPG o PNG
- **Relación de aspecto:** 16:9 recomendada

---

## Cómo tomar las capturas

### Opción 1: Emulador de Android Studio

1. Abre Android Studio
2. Inicia el emulador
3. Ejecuta la app: `flutter run`
4. Navega por las pantallas
5. Click en ícono de cámara 📷 en el emulador

### Opción 2: Dispositivo Real

1. Conecta tu Android por USB
2. Ejecuta: `flutter run`
3. En el dispositivo: **Botón Power + Volumen Abajo**

### Opción 3: Scrcpy (recomendado)

```bash
# Instalar scrcpy: https://github.com/Genymobile/scrcpy
scrcpy --record
```

---

## Pantallas a capturar (orden recomendado)

### 1. Login Screen
- Muestra el logo de SeniorSalud
- Campos de usuario y contraseña
- Botón "Iniciar Sesión" y "Solicitar Acceso"

### 2. Dashboard del Paciente
- Tarjetas de salud (presión arterial, glucosa, etc.)
- Gráficos o resúmenes
- Botones de acción

### 3. Registro de Presión Arterial
- Formulario con campos: sistólica, diastólica, frecuencia cardíaca
- Selector de fecha/hora

### 4. Historial de Mediciones
- Lista de registros anteriores
- Gráficos de tendencia

### 5. Alertas de Salud
- Notificaciones de valores críticos
- Recordatorios de medicación

### 6. Perfil de Usuario
- Datos del paciente
- Configuración

---

## Dimensiones recomendadas

| Tipo | Resolución | Uso |
|------|------------|-----|
| Teléfono | 1920x1080 | Majority dispositivos |
| Tablet | 2560x1600 | Opcional, para tablets |

---

## Tips

✅ Muestra la app en uso real (con datos)
✅ Usa fondo neutro o marco de dispositivo
✅ No incluyas texto promocional en las imágenes
✅ Ordena las capturas para contar una historia

❌ No uses screenshots de otras apps
❌ No incluyas información personal real
❌ No uses marcas de agua

---

## Carpeta de destino

Guarda las capturas en:
```
assets/screenshots/
  - screenshot_1_login.png
  - screenshot_2_dashboard.png
  - screenshot_3_registro.png
  - screenshot_4_historial.png
```
