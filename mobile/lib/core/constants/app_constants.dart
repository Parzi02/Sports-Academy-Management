class AppConstants {
  static const String merchantUpiId = 'sohan02mondal@ibl';
  static const String merchantName = 'Academy Training';

  static const Map<String, double> membershipPrices = {
    'monthly': 500.0,
    'quarterly': 1500.0,
    'yearly': 6000.0,
  };

  static String formatCurrency(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  static String getPlanLabel(String type) {
    switch (type.toLowerCase()) {
      case 'monthly':
        return 'Monthly Fee';
      case 'quarterly':
        return 'Quarterly Fee';
      case 'yearly':
        return 'Yearly Fee';
      default:
        return 'Standard Membership';
    }
  }
}
