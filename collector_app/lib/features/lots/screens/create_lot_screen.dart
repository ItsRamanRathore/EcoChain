import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:image/image.dart' as img;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/lot_repository.dart';
import '../../../core/ml/classifier_service.dart';

class CreateLotScreen extends ConsumerStatefulWidget {
  const CreateLotScreen({super.key});

  @override
  ConsumerState<CreateLotScreen> createState() => _CreateLotScreenState();
}

class _CreateLotScreenState extends ConsumerState<CreateLotScreen> {
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  final ClassifierService _classifier = ClassifierService();

  XFile? _imageFile;
  String? _selectedCategory;
  String _weightInput = '';
  String? _aiSuggestedCategory;

  final Map<String, Color> _categories = {
    'PCB': Colors.green.shade700,
    'Cable': Colors.orange.shade700,
    'Battery': Colors.red.shade700,
    'LCD': Colors.blue.shade700,
    'CRT': Colors.grey.shade800,
    'Motor': Colors.brown.shade700,
    'Plastic': Colors.purple.shade700,
    'Mixed': Colors.teal.shade700,
  };

  @override
  void initState() {
    super.initState();
    _classifier.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imageFile = photo;
        _aiSuggestedCategory = 'Analyzing...';
      });
      _nextPage();
      
      final bytes = await photo.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage != null) {
        final result = _classifier.classify(decodedImage);
        setState(() {
          _aiSuggestedCategory = result['category'] as String;
          _selectedCategory = result['category'] as String;
        });
      } else {
        setState(() {
          _aiSuggestedCategory = 'Unknown';
        });
      }
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _speakEstimate() async {
    final weight = double.tryParse(_weightInput) ?? 0.0;
    await _flutterTts.speak("Weight is $weight kilograms. Proceed to find recyclers.");
  }

  void _onKeypadTap(String value) {
    setState(() {
      if (value == 'C') {
        _weightInput = '';
      } else if (value == 'DEL') {
        if (_weightInput.isNotEmpty) {
          _weightInput = _weightInput.substring(0, _weightInput.length - 1);
        }
      } else if (value == '.') {
        if (!_weightInput.contains('.')) {
          _weightInput += value;
        }
      } else {
        _weightInput += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Handover Lot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageController.page == 0) {
              context.pop();
            } else {
              _prevPage();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildCameraScreen(),
          _buildCategoryScreen(),
          _buildWeightScreen(),
          _buildSummaryScreen(),
        ],
      ),
    );
  }

  Widget _buildCameraScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
          const SizedBox(height: 30),
          const Text(
            'Take a photo of the E-Waste lot',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 50),
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(Icons.camera, size: 30),
            label: const Text('Capture Photo', style: TextStyle(fontSize: 24)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScreen() {
    return Column(
      children: [
        if (_aiSuggestedCategory != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade100,
            child: Column(
              children: [
                const Text('AI Suggestion', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text(_aiSuggestedCategory!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Confirm or Select Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories.keys.elementAt(index);
              final color = _categories[cat]!;
              final isSelected = cat == _selectedCategory;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedCategory == null ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Next: Enter Weight', style: TextStyle(fontSize: 20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightScreen() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_weightInput kg', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(child: _buildKeypadRow(['1', '2', '3'])),
                Expanded(child: _buildKeypadRow(['4', '5', '6'])),
                Expanded(child: _buildKeypadRow(['7', '8', '9'])),
                Expanded(child: _buildKeypadRow(['.', '0', 'DEL'])),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton.icon(
                            onPressed: _speakEstimate,
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Hear Estimate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              foregroundColor: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            onPressed: _weightInput.isEmpty ? null : _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Review', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((k) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: InkWell(
              onTap: () => _onKeypadTap(k),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    k,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Lot Summary', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(_imageFile!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : Image.file(File(_imageFile!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 20),
          _buildSummaryRow('Category', _selectedCategory ?? ''),
          const Divider(),
          _buildSummaryRow('Weight', '$_weightInput kg'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final repo = ref.read(lotRepositoryProvider);
                try {
                  final lot = await repo.saveLotLocally(
                    category: _selectedCategory ?? 'Unknown',
                    weight: double.tryParse(_weightInput) ?? 0.0,
                    imagePath: _imageFile?.path ?? '',
                  );
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lot Saved! Finding Recyclers...'), backgroundColor: Colors.green),
                  );
                  // Ensure synced property is true for handover if we are online
                  lot.isSynced = true;
                  await lot.save();
                  context.go('/collector/handover/confirm', extra: lot);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save & Finish', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 20, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
