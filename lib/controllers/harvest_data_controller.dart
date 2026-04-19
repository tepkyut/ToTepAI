import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HarvestFormPage extends StatefulWidget {
  const HarvestFormPage({super.key});

  @override
  State<HarvestFormPage> createState() => _HarvestFormPageState();
}

class _HarvestFormPageState extends State<HarvestFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _totalPiecesController = TextEditingController();
  final TextEditingController _totalWeightController = TextEditingController();
  final TextEditingController _threeInOneController = TextEditingController();
  final TextEditingController _fourInOneController = TextEditingController();
  final TextEditingController _twoInOneController = TextEditingController();
  final TextEditingController _sardinesController = TextEditingController();
  final TextEditingController _forecastDataController = TextEditingController();
  final TextEditingController _forecastRemarksController = TextEditingController();


  bool _isSaving = false;

  @override
  void dispose() {
    _uidController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _totalPiecesController.dispose();
    _totalWeightController.dispose();
    _threeInOneController.dispose();
    _fourInOneController.dispose();
    _twoInOneController.dispose();
    _sardinesController.dispose();
    _forecastDataController.dispose();
    _forecastRemarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = _uidController.text.trim();
      final year = int.parse(_yearController.text.trim());
      final totalPieces = int.parse(_totalPiecesController.text.trim());
      final totalWeight = double.parse(_totalWeightController.text.trim());
      final threeInOne = int.parse(_threeInOneController.text.trim());
      final fourInOne = int.parse(_fourInOneController.text.trim());
      final twoInOne = int.parse(_twoInOneController.text.trim());
      final sardines = int.parse(_sardinesController.text.trim());

      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('harvest_data')
          .add(<String, dynamic>{
        'monthOfHarvest': _monthController.text.trim(),
        'yearOfHarvest': year,
        'totalPiecesOfHarvest': totalPieces,
        'totalWeightOfHarvest': totalWeight,
        'threeInOneTotalPieces': threeInOne,
        'fourInOneTotalPieces': fourInOne,
        'twoInOneTotalPieces': twoInOne,
        'sardinesTotalPieces': sardines,
        'timestamp': Timestamp.fromDate(now),
        'geminiForecastedData': {
          'rawText': _forecastDataController.text.trim(),
        },
        'geminiForecastRemarks': _forecastRemarksController.text.trim(),
        'userId': userId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harvest data saved successfully')),
      );
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harvest Data Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _uidController,
                  decoration: const InputDecoration(labelText: 'User UID'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the user UID';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _monthController,
                  decoration:
                      const InputDecoration(labelText: 'Month of Harvest'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the month of harvest';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'Year of Harvest (e.g. 2025)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the year of harvest';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 1900 || parsed > 2100) {
                      return 'Enter a valid year';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _totalPiecesController,
                  decoration: const InputDecoration(
                    labelText: 'Total Pieces of Harvest',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter total pieces';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _totalWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Total Weight of Harvest (kg)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter total weight';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _threeInOneController,
                  decoration: const InputDecoration(
                    labelText: '3-1 Total Pieces',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter 3-1 total pieces';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _fourInOneController,
                  decoration: const InputDecoration(
                    labelText: '4-1 Total Pieces',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter 4-1 total pieces';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _twoInOneController,
                  decoration: const InputDecoration(
                    labelText: '2-1 Total Pieces',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter 2-1 total pieces';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _sardinesController,
                  decoration: const InputDecoration(
                    labelText: 'Sardines Total Pieces',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter sardines total pieces';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Enter a valid integer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _forecastDataController,
                  decoration: const InputDecoration(
                    labelText: 'Gemini Forecasted Data (text or JSON)',
                  ),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _forecastRemarksController,
                  decoration: const InputDecoration(
                    labelText: 'Gemini Forecast Remarks',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Harvest Data'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
