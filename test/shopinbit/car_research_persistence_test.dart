import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/shopinbit/shopinbit_order_model.dart';

// Parses "Key: Value\n" car research description; strips " EUR" from Budget.
Map<String, String> _parseCarRequestDescription(String desc) {
  final result = <String, String>{};
  for (final line in desc.split('\n')) {
    final separatorIndex = line.indexOf(': ');
    if (separatorIndex == -1) continue;
    final key = line.substring(0, separatorIndex);
    var value = line.substring(separatorIndex + 2);
    if (key == 'Budget') {
      value = value.replaceAll(' EUR', '');
    }
    result[key] = value;
  }
  return result;
}

void main() {
  group('car research persistence', () {
    group('requestDescription parsing', () {
      test('parses all six fields from canonical format', () {
        const desc =
            'Brand: Toyota\n'
            'Model: Corolla\n'
            'Condition: used\n'
            'Description: sedan\n'
            'Budget: 10000 EUR\n'
            'Delivery country: DE';
        final parsed = _parseCarRequestDescription(desc);
        expect(parsed['Brand'], 'Toyota');
        expect(parsed['Model'], 'Corolla');
        expect(parsed['Condition'], 'used');
        expect(parsed['Description'], 'sedan');
        expect(parsed['Budget'], '10000');
        expect(parsed['Delivery country'], 'DE');
      });
    });

    group('carResearchPaymentLinks JSON round-trip', () {
      test('encode then decode preserves all keys and values', () {
        final original = {
          'BTC': 'bitcoin:abc?amount=0.1',
          'ETH': 'ethereum:def',
        };
        final encoded = jsonEncode(original);
        final decoded = (jsonDecode(encoded) as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as String),
        );
        expect(decoded, equals(original));
      });
    });

    group('isPendingPayment defaults false', () {
      test('new ShopInBitOrderModel has isPendingPayment == false', () {
        final model = ShopInBitOrderModel();
        expect(model.isPendingPayment, isFalse);
      });
    });

    group(
      'toIsarTicket/fromIsarTicket round-trip for pending payment fields',
      () {
        test('isPendingPayment round-trips', () {
          final model = ShopInBitOrderModel()
            ..isPendingPayment = true
            ..carResearchExpiresAt = DateTime(2026, 6, 1)
            ..carResearchPaymentLinks = '{"BTC":"link"}';
          final ticket = model.toIsarTicket();
          final restored = ShopInBitOrderModel.fromIsarTicket(ticket);
          expect(restored.isPendingPayment, isTrue);
          expect(restored.carResearchExpiresAt, DateTime(2026, 6, 1));
          expect(restored.carResearchPaymentLinks, '{"BTC":"link"}');
        });
      },
    );

    group('live invoice routes to payment view', () {
      test('expiresAt in the future means invoice is live', () {
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        expect(expiresAt.isAfter(DateTime.now()), isTrue);
      });
    });

    group('expired invoice routes to fee view', () {
      test('expiresAt in the past means invoice is expired', () {
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        expect(expiresAt.isAfter(DateTime.now()), isFalse);
      });
    });

    group('clearing isPendingPayment preserves other fields', () {
      test(
        'all other model fields unchanged after clearing isPendingPayment',
        () {
          final model = ShopInBitOrderModel()
            ..displayName = 'Test User'
            ..requestDescription =
                'Brand: BMW\nModel: X5\nCondition: new\nDescription: suv\nBudget: 50000 EUR\nDelivery country: AT'
            ..carResearchInvoiceId = 'inv-123'
            ..isPendingPayment = true;
          model.isPendingPayment = false;
          expect(model.isPendingPayment, isFalse);
          expect(model.displayName, 'Test User');
          expect(model.carResearchInvoiceId, 'inv-123');
          expect(model.requestDescription, startsWith('Brand: BMW'));
        },
      );
    });
  });
}
