import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/toast_utils.dart';
import '../providers/cart_provider.dart';

class OrderUpiPaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final String coachUpiId;
  final String coachName;
  
  const OrderUpiPaymentScreen({
    super.key, 
    required this.totalAmount,
    required this.coachUpiId,
    required this.coachName,
  });

  @override
  ConsumerState<OrderUpiPaymentScreen> createState() => _OrderUpiPaymentScreenState();
}

class _OrderUpiPaymentScreenState extends ConsumerState<OrderUpiPaymentScreen> {
  File? _screenshot;
  final _utrController = TextEditingController();
  bool _isProcessingImage = false;
  bool _isSubmitting = false;

  Future<void> _initiatePayment() async {
    final amount = widget.totalAmount;
    final refId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final url = 'upi://pay?pa=${widget.coachUpiId}&pn=${widget.coachName}&tr=$refId&am=$amount&cu=INR';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
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
        
        // 1. Validate Amount (Optional check, can be skipped or made less strict)
        final expectedAmount = widget.totalAmount.toStringAsFixed(0); 
        
        if (!fullText.contains(expectedAmount)) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification Warning: Amount "₹$expectedAmount" not clearly found in screenshot.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          // We won't block it strictly for orders, just warn.
        }

        // 2. Extract UTR
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
              const SnackBar(content: Text('Could not find a 12-digit UTR automatically. Please enter it manually.'), backgroundColor: Colors.orange),
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

  Future<void> _submitOrderWithProof() async {
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
      
      final cartItems = ref.read(cartProvider);
      final itemsData = cartItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'price': item.product.price,
        'name': item.product.name,
      }).toList();

      final apiClient = ref.read(apiClientProvider);

      final response = await apiClient.post('/orders', {
        'items': itemsData,
        'totalAmount': widget.totalAmount,
        'utrNumber': utr,
        'paymentProof': base64Image,
      });

      if (response.statusCode == 201) {
        ref.read(cartProvider.notifier).clearCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order placed successfully! Pending coach verification.'), backgroundColor: AppColors.success),
          );
          context.go('/member/products'); // Navigate back to shop
        }
      } else {
        throw Exception('Failed to place order');
      }
      
    } catch (e) {
      String errorMessage = 'Order submission failed. Please try again.';
      if (e is DioException && e.response?.data != null) {
         final data = e.response!.data;
         if (data is Map && data.containsKey('message')) {
           errorMessage = data['message'];
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
        title: const Text('Pay for Order'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Amount: ${AppConstants.formatCurrency(widget.totalAmount)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _initiatePayment,
                      icon: const Icon(Icons.payment, color: Colors.white, size: 20),
                      label: const Text('PAY NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
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
                onPressed: _isSubmitting ? null : _submitOrderWithProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SUBMIT ORDER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
