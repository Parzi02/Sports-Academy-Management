import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const OtpScreen({super.key, required this.data});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  int _timerValue = 28;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerValue--;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 4-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).post(
        '/auth/verify-otp', 
        {
          'phone': widget.data['phone'],
          'otp': otp,
          'sessionId': widget.data['sessionId'],
        }
      );
      
      final token = response.data['token'];
      await ref.read(authStateProvider.notifier).login(token);
      // GoRouter redirect logic will handle the rest
    } catch (e) {
      if (mounted) {
        String message = 'Failed to verify OTP. Please try again.';
        if (e is DioException && e.response?.data != null) {
          message = e.response?.data['error'] ?? message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
                'Verify OTP',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to ${widget.data['phone']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 3) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      if (val.isNotEmpty && index == 3) {
                        _verifyOtp();
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: _timerValue == 0 ? () {
                    setState(() {
                      _timerValue = 28;
                    });
                    _startTimer();
                  } : null,
                  child: Text(
                    _timerValue == 0 ? 'Resend' : 'Resend Code in ${_timerValue}s',
                    style: TextStyle(
                      color: _timerValue == 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyOtp,
                      child: const Text('CONTINUE'),
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
