import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/health_tip_card.dart';

class HealthTipsTab extends StatelessWidget {
  const HealthTipsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consejos de Salud',
            style: GoogleFonts.lexend(
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Información importante para cuidar tu salud',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 35),
          HealthTipCard(
            title: 'PRESIÓN ARTERIAL',
            icon: Icons.favorite,
            accentColor: const Color(0xFF0061A6),
            tips: [
              'Hipotensión (Baja): Menos de 90/60 mmHg (riesgo de mareos y caídas)',
              'Normal: Entre 90/60 y 120/80 mmHg',
              'Elevada: 120-129 / Menos de 80 mmHg',
              'Hipertensión (Alta): 130/80 mmHg o más (140/90 o más requiere control médico)',
              'Mide tu presión a la misma hora cada día en reposo',
              'Evita cafeína, tabaco o ejercicio 30 minutos antes',
              'Coloca el brazalete a la altura del corazón y apoya bien la espalda',
            ],
          ),
          const SizedBox(height: 25),
          HealthTipCard(
            title: 'PULSO CARDÍACO',
            icon: Icons.speed,
            accentColor: const Color(0xFFD81B60),
            tips: [
              'Bradicardia (Bajo): Menos de 60 latidos por minuto en reposo',
              'Normal: 60-100 latidos por minuto en reposo',
              'Taquicardia (Alto): Más de 100 latidos por minuto en reposo',
              'Mide tu pulso por las mañanas antes de levantarte de la cama',
              'Cuenta los latidos durante 60 segundos o usa un pulsioxímetro',
            ],
          ),
          const SizedBox(height: 25),
          HealthTipCard(
            title: 'GLUCOSA EN SANGRE',
            icon: Icons.water_drop,
            accentColor: Colors.blue,
            tips: [
              'Hipoglucemia (Baja): Menos de 70 mg/dL (tomar algo dulce de inmediato)',
              'Normal (En ayunas): 70-100 mg/dL',
              'Prediabetes (En ayunas): 100-125 mg/dL',
              'Diabetes (En ayunas): 126 mg/dL o más',
              'Normal (2 horas después de comer): Menos de 140 mg/dL',
              'Diabetes (2 horas después de comer): 200 mg/dL o más',
              'Realiza el pinchazo en los laterales del dedo para menor sensibilidad',
              'Registra si la medición fue antes o después de las comidas',
            ],
          ),
          const SizedBox(height: 25),
          HealthTipCard(
            title: 'PESO E IMC',
            icon: Icons.monitor_weight,
            accentColor: Colors.green,
            tips: [
              'Bajo Peso (Fragilidad): IMC menor de 22 kg/m² (evitar en adultos mayores)',
              'Peso Saludable: IMC entre 22 y 27 kg/m² (un ligero sobrepeso es protector)',
              'Sobrepeso: IMC entre 27 y 30 kg/m²',
              'Obesidad: IMC mayor de 30 kg/m²',
              'Pésate una vez por semana, por la mañana en ayunas y sin calzado',
              'Vigila pérdidas o ganancias súbitas de peso (pueden indicar retención de líquidos o desnutrición)',
              'Combina una alimentación equilibrada con ejercicio de fuerza moderado para mantener masa muscular',
            ],
          ),
        ],
      ),
    );
  }
}
