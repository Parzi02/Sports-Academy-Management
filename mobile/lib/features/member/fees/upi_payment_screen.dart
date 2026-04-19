import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/member_providers.dart';
import '../repositories/member_repository.dart';

class UpiPaymentScreen extends ConsumerStatefulWidget {
  final String initialPlan;
  final String coachUpiId;
  final String coachName;
  const UpiPaymentScreen({
    super.key, 
    required this.initialPlan,
    required this.coachUpiId,
    required this.coachName,
  });

  @override
  ConsumerState<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends ConsumerState<UpiPaymentScreen> {
  late String _selectedPlan;
  final Map<String, double> _planPrices = AppConstants.membershipPrices;

  int _currentStep = 1; // Start directly at Submit Proof
  
  File? _screenshot;
  final _utrController = TextEditingController();
  bool _isProcessingImage = false;
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan.toLowerCase();
  }

  // Using coach details passed from the dashboard
  String get _targetUpiId => widget.coachUpiId;
  String get _merchantName => widget.coachName;

  Future<void> _initiatePayment() async {
    final amount = _planPrices[_selectedPlan]!;
    final refId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final url = 'upi://pay?pa=$_targetUpiId&pn=$_merchantName&tr=$refId&am=$amount&cu=INR';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback or Simulation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simulated: UPI app not found, please select a screenshot for proof.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error launching UPI: $e')),
        );
      }
    }
    
    // Always move to step 1 (Proof submission)
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _pickAndProcessImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _screenshot = File(pickedFile.path);
        _isProcessingImage = true;
      });

      // Run OCR
      try {
        final inputImage = InputImage.fromFile(_screenshot!);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        
        final fullText = recognizedText.text.toLowerCase();
        // 1. Validate Amount
        final expectedAmount = _planPrices[_selectedPlan]!.toStringAsFixed(0); // Look for whole number part at least
        
        if (!fullText.contains(expectedAmount)) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification Failed: Amount "₹$expectedAmount" not found in screenshot.'),
                backgroundColor: AppColors.alert,
              ),
            );
          }
          setState(() => _screenshot = null); // Strict blocking
          return;
        }

        // 3. Extract UTR
        String extractedUtr = '';
        final RegExp utrRegex = RegExp(r'\b\d{12}\b');
        
        for (TextBlock block in recognizedText.blocks) {
          final match = utrRegex.firstMatch(block.text);
          if (match != null) {
            extractedUtr = match.group(0)!;
            break;
          }
        }
        
        if (extractedUtr.isNotEmpty) {
          _utrController.text = extractedUtr;
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Screenshot Verified & UTR Extracted!'), backgroundColor: AppColors.success),
            );
          }
        } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Merchant & Amount Verified, but could not find a 12-digit UTR. Please enter it manually.'), backgroundColor: Colors.orange),
            );
          }
        }
        
        textRecognizer.close();
      } catch (e) {
         if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error scanning image: $e'), backgroundColor: AppColors.alert),
            );
          }
      } finally {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<void> _submitProof() async {
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a payment screenshot.')));
      return;
    }
    
    final utr = _utrController.text.trim();
    if (utr.isEmpty || utr.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 12-digit UTR/Reference number.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final bytes = await _screenshot!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      await ref.read(memberRepositoryProvider).submitPaymentProof(
        _planPrices[_selectedPlan]!,
        _selectedPlan,
        utr,
        base64Image,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proof submitted successfully! It is pending admin verification.'), backgroundColor: AppColors.success),
        );
        ref.invalidate(paymentHistoryProvider);
        Navigator.pop(context); // Go back to Fees screen
      }
      
    } catch (e) {
      String errorMessage = 'Submission failed. Please try again.';
      if (e is DioException && e.response?.data != null) {
         final data = e.response!.data;
         if (data is Map && data.containsKey('error')) {
           errorMessage = data['error'];
         }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.alert),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Pay via UPI'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildProofSubmission(),
    );
  }

  Widget _buildProofSubmission() {
    final amount = _planPrices[_selectedPlan] ?? 0.0;
    final label = AppConstants.getPlanLabel(_selectedPlan);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Amount: ${AppConstants.formatCurrency(amount)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _initiatePayment, 
                  child: const Text('RETRY PAY', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Submit Proof', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Upload the screenshot of your successful UPI payment. We will extract the UTR automatically.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          
          GestureDetector(
            onTap: _pickAndProcessImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.2), style: BorderStyle.solid),
                image: _screenshot != null ? DecorationImage(image: FileImage(_screenshot!), fit: BoxFit.cover) : null,
              ),
              child: _screenshot == null 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_photo_alternate, size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Tap to select screenshot', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  )
                : null,
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_isProcessingImage)
             Center(child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Column(
                 children: const [
                   CircularProgressIndicator(),
                   SizedBox(height: 8),
                   Text('Extracting UTR via ML Kit...'),
                 ],
               ),
             )),
             
          const Text('UTR / Reference Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _utrController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: InputDecoration(
              hintText: 'e.g. 123456789012',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                padding: const EdgeInsets.symmetric(vertical: 16), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('SUBMIT PROOF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
