import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/member_providers.dart';
import 'upi_payment_screen.dart';

class FeesScreen extends ConsumerWidget {
  const FeesScreen({super.key});

  Future<void> _launchUPI(BuildContext context, String planType) async {
    final amount = AppConstants.membershipPrices[planType.toLowerCase()] ?? 0.0;
    final txnId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    final url = 'upi://pay?pa=${AppConstants.merchantUpiId}&pn=${AppConstants.merchantName}&tr=$txnId&am=$amount&cu=INR';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find a UPI app. Please install GPay, PhonePe, or BHIM.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error launching UPI: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(memberDashboardProvider);
    final historyState = ref.watch(paymentHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Fees & Transactions'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              ref.invalidate(memberDashboardProvider);
              ref.invalidate(paymentHistoryProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
            ref.refresh(memberDashboardProvider.future);
            ref.refresh(paymentHistoryProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Current Status Card matching Page 5
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: dashboardState.when(
                  data: (data) {
                    final isPending = data.isPaymentPending;
                    final dueDateTime = data.dueDate != null ? DateTime.parse(data.dueDate!) : null;
                    
                    // Logic: Expiring soon (within 3 days) or already expired
                    final bool isDueSoonOrExpired = dueDateTime == null || 
                                                     dueDateTime.isBefore(DateTime.now().add(const Duration(days: 3)));
                    
                    // Show "PAY NOW" ONLY if NOT pending AND (Expired OR Expiring within 3 days)
                    final bool showPayButton = !isPending && isDueSoonOrExpired && data.feeStatus != 'paid';

                    if (data.feeStatus == 'paid' && !isDueSoonOrExpired) {
                       return const _NoDuesCard();
                    }

                    if (isPending) {
                       return const _PendingApprovalCard();
                    }

                    if (!showPayButton && data.feeStatus != 'paid') {
                       // Membership is active and expires in more than 3 days
                       return _ActiveMembershipCard(dueDate: data.dueDate);
                    }

                    return _DueStatusCard(
                      membershipType: data.membershipType,
                      dueDate: data.dueDate,
                      onPay: () async {
                         await _launchUPI(context, data.membershipType);
                         if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => UpiPaymentScreen(initialPlan: data.membershipType)));
                         }
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Text('Error: $e'),
                ),
              ),
              
              // Transaction History Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    historyState.when(
                      data: (history) {
                        if (history.isEmpty) {
                          return const Center(child: Text('No transactions found.'));
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = history[index];
                            return _TransactionCard(
                              category: '${tx['plan_type'].toString().toUpperCase()} Plan',
                              date: DateFormat('dd MMM yyyy').format(DateTime.parse(tx['created_at'])),
                              amount: tx['amount'].toString(),
                              method: 'UPI Bank Transfer',
                              status: tx['status'],
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, __) => Text('Failed to load history: $e'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 100), // Spacing for bottom
            ],
          ),
        ),
      ),
    );
  }
}

class _DueStatusCard extends StatelessWidget {
  final VoidCallback onPay;
  final String membershipType;
  final String? dueDate;
  
  const _DueStatusCard({
    required this.onPay,
    required this.membershipType,
    this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final amount = AppConstants.membershipPrices[membershipType.toLowerCase()] ?? 0.0;
    final label = AppConstants.getPlanLabel(membershipType);
    final formattedDueDate = dueDate != null 
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(dueDate!))
        : 'TBD';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Training Membership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('DUE', style: TextStyle(color: AppColors.alert, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(AppConstants.formatCurrency(amount), style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Due Date: $formattedDueDate', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPay,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orange, size: 64),
          const SizedBox(height: 24),
          const Text('Waiting for Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Your payment proof is being verified by the admin. Please wait.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ActiveMembershipCard extends StatelessWidget {
  final String? dueDate;
  const _ActiveMembershipCard({this.dueDate});

  @override
  Widget build(BuildContext context) {
    final formattedDate = dueDate != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(dueDate!)) : 'TBD';
    
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: AppColors.primary, size: 60),
          const SizedBox(height: 24),
          const Text('Membership Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text('Your plan is valid until $formattedDate.', style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text('Renewal opens 3 days before expiry.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _NoDuesCard extends StatelessWidget {
  const _NoDuesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 64),
          const SizedBox(height: 24),
          const Text('No Dues Left', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Your fees are up to date. Keep training!', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final String category;
  final String date;
  final String amount;
  final String method;
  final String status;

  const _TransactionCard({
    required this.category,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    bool isPending = status.toLowerCase() == 'pending';
    bool isRejected = status.toLowerCase() == 'rejected';
    Color iconColor = isPending ? AppColors.alert : (isRejected ? Colors.red : AppColors.success);
    IconData iconData = isPending ? Icons.pending_actions : (isRejected ? Icons.cancel : Icons.check);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$date • $method', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹ $amount', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(isPending ? 'WAITING FOR THE APPROVAL OF THE ADMIN' : status.toUpperCase(), style: TextStyle(color: iconColor, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
