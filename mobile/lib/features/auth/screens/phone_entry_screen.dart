import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  final String role;
  const PhoneEntryScreen({super.key, required this.role});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    if (_controller.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).post(
        '/auth/send-otp', 
        {'phone': '91${_controller.text}'}
      );
      
      if (mounted) {
        context.push('/auth/otp', extra: {
          'phone': '91${_controller.text}',
          'role': widget.role,
          'sessionId': response.data['sessionId'],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary, onPressed: () => context.pop()),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Mobile',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 10-digit phone number to receive a code.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  prefixText: '+91 ',
                  prefixStyle: Theme.of(context).textTheme.titleLarge,
                  hintText: '98765 43210',
                  counterText: '',
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('GET OTP'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
