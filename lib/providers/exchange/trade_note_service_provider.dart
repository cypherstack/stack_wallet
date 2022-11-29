import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epicmobile/services/trade_notes_service.dart';

final tradeNoteServiceProvider =
    ChangeNotifierProvider<TradeNotesService>((ref) => TradeNotesService());
