import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/models/isar/exchange_cache/currency.dart';
import 'package:stackwallet/services/exchange/exchange_data_loading_service.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

class EthTokenIcon extends ConsumerStatefulWidget {
  const EthTokenIcon({
    Key? key,
    required this.contractAddress,
    this.size = 22,
  }) : super(key: key);

  final String contractAddress;
  final double size;

  @override
  ConsumerState<EthTokenIcon> createState() => _EthTokenIconState();
}

class _EthTokenIconState extends ConsumerState<EthTokenIcon> {
  late final String? imageUrl;

  @override
  void initState() {
    imageUrl = ExchangeDataLoadingService.instance.isar.currencies
        .where()
        .filter()
        .tokenContractEqualTo(widget.contractAddress, caseSensitive: false)
        .findFirstSync()
        ?.image;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SvgPicture.asset(
        ref.watch(coinIconProvider(Coin.ethereum)),
        width: widget.size,
        height: widget.size,
      );
    } else {
      return SvgPicture.network(
        imageUrl!,
        width: widget.size,
        height: widget.size,
      );
    }
  }
}
