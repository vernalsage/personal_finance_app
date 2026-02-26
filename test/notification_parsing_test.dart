import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_app/application/services/transaction_parser_service.dart';

void main() {
  late TransactionParserService parser;

  setUp(() {
    parser = TransactionParserService();
  });

  group('Nigerian Bank Notification Parsing', () {
    test('GTBank Debit Notification', () {
      const text = 'Debit: NGN 10,000.00 | Desc: TRF TO JOHN DOE | Date: 26-FEB-2026 | Bal: NGN 50,000.00';
      final result = parser.parseNotification(text);

      expect(result.amountMinor, 1000000); // 10,000.00 * 100
      expect(result.transactionType, 'debit');
      expect(result.merchantString, contains('JOHN DOE'));
      expect(result.confidenceScore, greaterThanOrEqualTo(80));
    });

    test('Zenith Bank Credit Notification', () {
      const text = 'Transaction Notification | Acct: 123... | Amt: 15,000.00 CR | Desc: TRANSFER FROM BANK | Date: 2026-02-26 | Bal: 100,000.00';
      final result = parser.parseNotification(text);

      expect(result.amountMinor, 1500000);
      expect(result.transactionType, 'credit');
      expect(result.confidenceScore, greaterThanOrEqualTo(80));
    });

    test('OPay Success Notification', () {
      const text = "Success: You've sent ₦2,000 to Jane Doe. Your new balance is ₦5,000.";
      final result = parser.parseNotification(text);

      expect(result.amountMinor, 200000); // 2,000 * 100
      expect(result.transactionType, 'debit');
      expect(result.merchantString, contains('Jane Doe'));
      expect(result.confidenceScore, greaterThanOrEqualTo(80));
    });

    test('Generic SMS Notification', () {
      const text = 'Acct: 1234567890 | Amt: 5,500.00 Dr | Desc: POS PURCHASE | Bal: 20,000.00';
      final result = parser.parseNotification(text);

      expect(result.amountMinor, 550000);
      expect(result.transactionType, 'debit');
      expect(result.confidenceScore, greaterThanOrEqualTo(80));
    });
  });
}
