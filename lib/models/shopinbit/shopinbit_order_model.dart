import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../db/drift/shared_db/shared_database.dart';
import '../../db/drift/shared_db/tables/shopin_bit_tickets.dart';
import '../../services/shopinbit/src/models/ticket.dart';
import '../../themes/stack_colors.dart';

// these enum indexes are stored in a db. Do not edit order
enum ShopInBitCategory { concierge, travel, car }

// these enum indexes are stored in a db. Do not edit order
enum ShopInBitOrderStatus {
  pending,
  reviewing,
  offerAvailable,
  accepted,
  paymentPending,
  paid,
  shipping,
  delivered,
  closed,
  cancelled,
  refunded;

  String get label => switch (this) {
    .pending => "Pending",
    .reviewing => "Under review",
    .offerAvailable => "Offer available",
    .accepted => "Accepted",
    .paymentPending => "Awaiting payment",
    .paid => "Paid",
    .shipping => "Shipping",
    .delivered => "Delivered",
    .closed => "Closed",
    .cancelled => "Cancelled",
    .refunded => "Refunded",
  };

  Color getColor(StackColors colors) => switch (this) {
    .delivered => colors.accentColorGreen,
    .offerAvailable => colors.accentColorBlue,
    .pending || .reviewing => colors.accentColorYellow,
    .closed || .cancelled || .refunded => colors.textSubtitle1,
    _ => colors.accentColorDark,
  };
}

class ShopInBitMessage {
  final String text;
  final DateTime timestamp;
  final bool isFromUser;

  const ShopInBitMessage({
    required this.text,
    required this.timestamp,
    required this.isFromUser,
  });
}

class ShopInBitOrderModel extends ChangeNotifier {
  String _displayName = "";
  String get displayName => _displayName;
  set displayName(String value) {
    if (_displayName != value) {
      _displayName = value;
      notifyListeners();
    }
  }

  bool _privacyAccepted = false;
  bool get privacyAccepted => _privacyAccepted;
  set privacyAccepted(bool value) {
    if (_privacyAccepted != value) {
      _privacyAccepted = value;
      notifyListeners();
    }
  }

  ShopInBitCategory? _category;
  ShopInBitCategory? get category => _category;
  set category(ShopInBitCategory? value) {
    if (_category != value) {
      _category = value;
      notifyListeners();
    }
  }

  bool _guidelinesAccepted = false;
  bool get guidelinesAccepted => _guidelinesAccepted;
  set guidelinesAccepted(bool value) {
    if (_guidelinesAccepted != value) {
      _guidelinesAccepted = value;
      notifyListeners();
    }
  }

  String _requestDescription = "";
  String get requestDescription => _requestDescription;
  set requestDescription(String value) {
    if (_requestDescription != value) {
      _requestDescription = value;
      notifyListeners();
    }
  }

  String _deliveryCountry = "";
  String get deliveryCountry => _deliveryCountry;
  set deliveryCountry(String value) {
    if (_deliveryCountry != value) {
      _deliveryCountry = value;
      notifyListeners();
    }
  }

  int _apiTicketId = 0;
  int get apiTicketId => _apiTicketId;
  set apiTicketId(int value) {
    if (_apiTicketId != value) {
      _apiTicketId = value;
      notifyListeners();
    }
  }

  String? _ticketId;
  String? get ticketId => _ticketId;
  set ticketId(String? value) {
    if (_ticketId != value) {
      _ticketId = value;
      notifyListeners();
    }
  }

  ShopInBitOrderStatus _status = ShopInBitOrderStatus.pending;
  ShopInBitOrderStatus get status => _status;
  set status(ShopInBitOrderStatus value) {
    if (_status != value) {
      _status = value;
      notifyListeners();
    }
  }

  // The most recent raw API state string, persisted alongside _status so that
  // we can recover from contract drift (renames / new states) without losing
  // history. _status is the parsed/mapped value; _statusRaw is the source of
  // truth straight from the API.
  String? _statusRaw;
  String? get statusRaw => _statusRaw;
  set statusRaw(String? value) {
    if (_statusRaw != value) {
      _statusRaw = value;
      notifyListeners();
    }
  }

  String? _offerProductName;
  String? get offerProductName => _offerProductName;

  String? _offerPrice;
  String? get offerPrice => _offerPrice;

  void setOffer({required String productName, required String price}) {
    _offerProductName = productName;
    _offerPrice = price;
    _status = ShopInBitOrderStatus.offerAvailable;
    notifyListeners();
  }

  String _shippingName = "";
  String get shippingName => _shippingName;

  String _shippingStreet = "";
  String get shippingStreet => _shippingStreet;

  String _shippingCity = "";
  String get shippingCity => _shippingCity;

  String _shippingPostalCode = "";
  String get shippingPostalCode => _shippingPostalCode;

  String _shippingCountry = "";
  String get shippingCountry => _shippingCountry;

  void setShippingAddress({
    required String name,
    required String street,
    required String city,
    required String postalCode,
    required String country,
  }) {
    _shippingName = name;
    _shippingStreet = street;
    _shippingCity = city;
    _shippingPostalCode = postalCode;
    _shippingCountry = country;
    notifyListeners();
  }

  String? _paymentMethod;
  String? get paymentMethod => _paymentMethod;
  set paymentMethod(String? value) {
    if (_paymentMethod != value) {
      _paymentMethod = value;
      notifyListeners();
    }
  }

  String? _carResearchInvoiceId;
  String? get carResearchInvoiceId => _carResearchInvoiceId;
  set carResearchInvoiceId(String? value) {
    if (_carResearchInvoiceId != value) {
      _carResearchInvoiceId = value;
      notifyListeners();
    }
  }

  String? _feeTicketNumber;
  String? get feeTicketNumber => _feeTicketNumber;
  set feeTicketNumber(String? value) {
    if (_feeTicketNumber != value) {
      _feeTicketNumber = value;
      notifyListeners();
    }
  }

  bool _needsCreateRequest = false;
  bool get needsCreateRequest => _needsCreateRequest;
  set needsCreateRequest(bool value) {
    if (_needsCreateRequest != value) {
      _needsCreateRequest = value;
      notifyListeners();
    }
  }

  bool _isPendingPayment = false;
  bool get isPendingPayment => _isPendingPayment;
  set isPendingPayment(bool value) {
    if (_isPendingPayment != value) {
      _isPendingPayment = value;
      notifyListeners();
    }
  }

  DateTime? _carResearchExpiresAt;
  DateTime? get carResearchExpiresAt => _carResearchExpiresAt;
  set carResearchExpiresAt(DateTime? value) {
    if (_carResearchExpiresAt != value) {
      _carResearchExpiresAt = value;
      notifyListeners();
    }
  }

  String? _carResearchPaymentLinks;
  String? get carResearchPaymentLinks => _carResearchPaymentLinks;
  set carResearchPaymentLinks(String? value) {
    if (_carResearchPaymentLinks != value) {
      _carResearchPaymentLinks = value;
      notifyListeners();
    }
  }

  List<ShopInBitMessage> _messages = [];
  List<ShopInBitMessage> get messages => List.unmodifiable(_messages);
  void addMessage(ShopInBitMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
  }

  ShopInBitTicketsCompanion toCompanion() {
    assert(_ticketId != null, "ticketId must be set before persisting");

    final List<ShopInBitTicketMessage> messages = _messages
        .map(
          (m) => ShopInBitTicketMessage(
            text: m.text,
            timestamp: m.timestamp,
            isFromUser: m.isFromUser,
          ),
        )
        .toList();

    return ShopInBitTicketsCompanion(
      ticketId: Value(_ticketId!),
      displayName: Value(_displayName),
      category: Value(_category ?? ShopInBitCategory.concierge),
      status: Value(_status),
      statusRaw: Value(_statusRaw),
      requestDescription: Value(_requestDescription),
      deliveryCountry: Value(_deliveryCountry),
      offerProductName: Value(_offerProductName),
      offerPrice: Value(_offerPrice),
      shippingName: Value(_shippingName),
      shippingStreet: Value(_shippingStreet),
      shippingCity: Value(_shippingCity),
      shippingPostalCode: Value(_shippingPostalCode),
      shippingCountry: Value(_shippingCountry),
      paymentMethod: Value(_paymentMethod),
      apiTicketId: Value(_apiTicketId),
      carResearchInvoiceId: Value(_carResearchInvoiceId),
      feeTicketNumber: Value(_feeTicketNumber),
      needsCreateRequest: Value(_needsCreateRequest),
      isPendingPayment: Value(_isPendingPayment),
      carResearchExpiresAt: Value(_carResearchExpiresAt),
      carResearchPaymentLinks: Value(_carResearchPaymentLinks),
      messages: Value(messages),
      createdAt: Value(DateTime.now()),
    );
  }

  static ShopInBitOrderModel fromDriftRow(ShopInBitTicket ticket) {
    final List<ShopInBitMessage> messages = ticket.messages
        .map(
          (m) => ShopInBitMessage(
            text: m.text,
            timestamp: m.timestamp,
            isFromUser: m.isFromUser,
          ),
        )
        .toList();

  static ShopInBitOrderModel fromIsarTicket(ShopInBitTicket ticket) {
    return ShopInBitOrderModel()
      .._displayName = ticket.displayName
      .._category = ticket.category
      .._apiTicketId = ticket.apiTicketId
      .._ticketId = ticket.ticketId
      .._status = ticket.status
      .._statusRaw = ticket.statusRaw
      .._requestDescription = ticket.requestDescription
      .._deliveryCountry = ticket.deliveryCountry
      .._offerProductName = ticket.offerProductName
      .._offerPrice = ticket.offerPrice
      .._shippingName = ticket.shippingName
      .._shippingStreet = ticket.shippingStreet
      .._shippingCity = ticket.shippingCity
      .._shippingPostalCode = ticket.shippingPostalCode
      .._shippingCountry = ticket.shippingCountry
      .._paymentMethod = ticket.paymentMethod
      .._carResearchInvoiceId = ticket.carResearchInvoiceId
      .._feeTicketNumber = ticket.feeTicketNumber
      .._needsCreateRequest = ticket.needsCreateRequest
      .._isPendingPayment = ticket.isPendingPayment
      .._carResearchExpiresAt = ticket.carResearchExpiresAt
      .._carResearchPaymentLinks = ticket.carResearchPaymentLinks
      .._messages = messages;
  }

  static ShopInBitOrderStatus? statusFromTicketState(TicketState state) {
    switch (state) {
      case TicketState.newTicket:
        return ShopInBitOrderStatus.pending;
      case TicketState.checking:
      case TicketState.inProgress:
      case TicketState.replyNeeded:
        return ShopInBitOrderStatus.reviewing;
      case TicketState.offerAvailable:
        return ShopInBitOrderStatus.offerAvailable;
      case TicketState.clearing:
        return ShopInBitOrderStatus.accepted;
      case TicketState.pendingClose:
        return ShopInBitOrderStatus.paymentPending;
      case TicketState.shipped:
        return ShopInBitOrderStatus.shipping;
      case TicketState.fulfilled:
        return ShopInBitOrderStatus.delivered;
      case TicketState.closed:
      case TicketState.merged:
        return ShopInBitOrderStatus.closed;
      case TicketState.closedCancelled:
        return ShopInBitOrderStatus.cancelled;
      case TicketState.refunded:
        return ShopInBitOrderStatus.refunded;
      case TicketState.unknown:
        return null;
    }
  }
}
