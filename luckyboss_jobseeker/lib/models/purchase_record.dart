/// SPEC 65 — a job seeker's purchase history.
///
/// Every paid application produces one of these. The transaction id is what a
/// seeker quotes when something goes wrong, so it is generated once at payment
/// time and never recomputed.
class PurchaseRecord {
  final String transactionId;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final double amount;
  final String currency;
  final DateTime paidAt;
  final String gateway;
  final String status;

  const PurchaseRecord({
    required this.transactionId,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.amount,
    required this.currency,
    required this.paidAt,
    this.gateway = 'Card',
    this.status = 'Paid',
  });

  /// Currency code, never a bare symbol — the platform spans several markets
  /// and "$" is ambiguous across them.
  String get amountDisplay => '$currency ${amount.toStringAsFixed(2)}';
}
