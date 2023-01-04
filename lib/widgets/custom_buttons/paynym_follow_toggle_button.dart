import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/models/paynym/paynym_account_lite.dart';
import 'package:stackwallet/models/paynym/paynym_response.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/providers/global/paynym_api_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/providers/wallet/my_paynym_account_state_provider.dart';
import 'package:stackwallet/services/coins/coin_paynym_extension.dart';
import 'package:stackwallet/services/coins/dogecoin/dogecoin_wallet.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';

class PaynymFollowToggleButton extends ConsumerStatefulWidget {
  const PaynymFollowToggleButton({
    Key? key,
    required this.walletId,
    required this.paymentCodeStringToFollow,
  }) : super(key: key);

  final String walletId;
  final String paymentCodeStringToFollow;

  @override
  ConsumerState<PaynymFollowToggleButton> createState() =>
      _PaynymFollowToggleButtonState();
}

class _PaynymFollowToggleButtonState
    extends ConsumerState<PaynymFollowToggleButton> {
  final isDesktop = Util.isDesktop;

  Future<bool> follow() async {
    bool loadingPopped = false;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const LoadingIndicator(
          width: 200,
        ),
      ).then(
        (_) => loadingPopped = true,
      ),
    );

    final wallet = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as DogecoinWallet;

    final followedAccount = await ref
        .read(paynymAPIProvider)
        .nym(widget.paymentCodeStringToFollow, true);

    final myPCode = await wallet.getPaymentCode();

    PaynymResponse<String> token =
        await ref.read(paynymAPIProvider).token(myPCode.toString());

    // sign token with notification private key
    String signature = await wallet.signStringWithNotificationKey(token.value!);

    var result = await ref.read(paynymAPIProvider).follow(
        token.value!, signature, followedAccount.value!.codes.first.code);

    int i = 0;
    for (;
        i < 10 &&
            result.statusCode == 401; //"401 Unauthorized - Bad signature";
        i++) {
      token = await ref.read(paynymAPIProvider).token(myPCode.toString());

      // sign token with notification private key
      signature = await wallet.signStringWithNotificationKey(token.value!);

      result = await ref.read(paynymAPIProvider).follow(
          token.value!, signature, followedAccount.value!.codes.first.code);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      print("RRR result: $result");
    }

    print("Follow result: $result on try $i");

    if (result.value!.following == followedAccount.value!.nymID) {
      if (!loadingPopped && mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "You are following ${followedAccount.value!.nymName}",
          context: context,
        ),
      );

      final myAccount = ref.read(myPaynymAccountStateProvider.state).state!;

      myAccount.following.add(
        PaynymAccountLite(
          followedAccount.value!.nymID,
          followedAccount.value!.nymName,
          followedAccount.value!.codes.first.code,
          followedAccount.value!.codes.first.segwit,
        ),
      );

      ref.read(myPaynymAccountStateProvider.state).state = myAccount.copyWith();

      setState(() {
        isFollowing = true;
      });

      return true;
    } else {
      if (!loadingPopped && mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to follow ${followedAccount.value!.nymName}",
          context: context,
        ),
      );

      return false;
    }
  }

  Future<bool> unfollow() async {
    bool loadingPopped = false;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => const LoadingIndicator(
          width: 200,
        ),
      ).then(
        (_) => loadingPopped = true,
      ),
    );

    final wallet = ref
        .read(walletsChangeNotifierProvider)
        .getManager(widget.walletId)
        .wallet as DogecoinWallet;

    final followedAccount = await ref
        .read(paynymAPIProvider)
        .nym(widget.paymentCodeStringToFollow, true);

    final myPCode = await wallet.getPaymentCode();

    PaynymResponse<String> token =
        await ref.read(paynymAPIProvider).token(myPCode.toString());

    // sign token with notification private key
    String signature = await wallet.signStringWithNotificationKey(token.value!);

    var result = await ref.read(paynymAPIProvider).unfollow(
        token.value!, signature, followedAccount.value!.codes.first.code);

    int i = 0;
    for (;
        i < 10 &&
            result.statusCode == 401; //"401 Unauthorized - Bad signature";
        i++) {
      token = await ref.read(paynymAPIProvider).token(myPCode.toString());

      // sign token with notification private key
      signature = await wallet.signStringWithNotificationKey(token.value!);

      result = await ref.read(paynymAPIProvider).unfollow(
          token.value!, signature, followedAccount.value!.codes.first.code);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      print("unfollow RRR result: $result");
    }

    print("Unfollow result: $result on try $i");

    if (result.value!.unfollowing == followedAccount.value!.nymID) {
      if (!loadingPopped && mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.success,
          message: "You have unfollowed ${followedAccount.value!.nymName}",
          context: context,
        ),
      );

      final myAccount = ref.read(myPaynymAccountStateProvider.state).state!;

      myAccount.following
          .removeWhere((e) => e.nymId == followedAccount.value!.nymID);

      ref.read(myPaynymAccountStateProvider.state).state = myAccount.copyWith();

      setState(() {
        isFollowing = false;
      });

      return true;
    } else {
      if (!loadingPopped && mounted) {
        Navigator.of(context, rootNavigator: isDesktop).pop();
      }

      unawaited(
        showFloatingFlushBar(
          type: FlushBarType.warning,
          message: "Failed to unfollow ${followedAccount.value!.nymName}",
          context: context,
        ),
      );

      return false;
    }
  }

  bool _lock = false;
  late bool isFollowing;

  @override
  void initState() {
    isFollowing = ref
        .read(myPaynymAccountStateProvider.state)
        .state!
        .following
        .where((e) => e.code == widget.paymentCodeStringToFollow)
        .isNotEmpty;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      width: isDesktop ? 120 : 84,
      buttonHeight: isDesktop ? ButtonHeight.s : ButtonHeight.l,
      label: isFollowing ? "Unfollow" : "Follow",
      onPressed: () async {
        if (!_lock) {
          _lock = true;
          if (isFollowing) {
            await unfollow();
          } else {
            await follow();
          }
          _lock = false;
        }
      },
    );
  }
}
