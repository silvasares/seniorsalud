import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/readings_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_input_field.dart';

class AddReadingScreen extends StatefulWidget {
  final String userId;
  const AddReadingScreen({super.key, required this.userId});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final rp = context.read<ReadingsProvider>();
    final success = await rp.addReading(
      userId: widget.userId,
      systolic: int.tryParse(_systolicController.text),
      diastolic: int.tryParse(_diastolicController.text),
      heartRate: int.tryParse(_heartRateController.text),
      glucose: int.tryParse(_glucoseController.text),
      weight: double.tryParse(_weightController.text),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medición guardada con éxito')),
      );
    } else if (mounted && rp.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rp.error!)),
      );
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _glucoseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nueva Medición',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registra tus constantes vitales',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Introduce tus lecturas de hoy. Deja en blanco los campos que no vayas a medir.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),
            AppInputField(
              controller: _systolicController,
              labelText: 'Tensión Sistólica (Alta)',
              hint: 'mmHg',
              icon: Icons.favorite,
              iconColor: Colors.redAccent,
              keyboardType: TextInputType.number,
              suffixText: 'mmHg',
            ),
            const SizedBox(height: 18),
            AppInputField(
              controller: _diastolicController,
              labelText: 'Tensión Diastólica (Baja)',
              hint: 'mmHg',
              icon: Icons.favorite_border,
              iconColor: Colors.orangeAccent,
              keyboardType: TextInputType.number,
              suffixText: 'mmHg',
            ),
            const SizedBox(height: 18),
            AppInputField(
              controller: _heartRateController,
              labelText: 'Pulso',
              hint: 'bpm',
              icon: Icons.speed,
              iconColor: Colors.pinkAccent,
              keyboardType: TextInputType.number,
              suffixText: 'bpm',
            ),
            const SizedBox(height: 18),
            AppInputField(
              controller: _glucoseController,
              labelText: 'Glucosa',
              hint: 'mg/dL',
              icon: Icons.water_drop,
              iconColor: Colors.blueAccent,
              keyboardType: TextInputType.number,
              suffixText: 'mg/dL',
            ),
            const SizedBox(height: 18),
            AppInputField(
              controller: _weightController,
              labelText: 'Peso',
              hint: 'kg',
              icon: Icons.monitor_weight,
              iconColor: Colors.deepPurpleAccent,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              suffixText: 'kg',
            ),
            const SizedBox(height: 35),
            if (_isSaving)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 70),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'GUARDAR MEDICIÓN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
