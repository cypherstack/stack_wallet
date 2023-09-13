import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/tor_settings/tor_settings_view.dart';
import 'package:stackwallet/services/event_bus/events/global/tor_connection_status_changed_event.dart';
import 'package:stackwallet/services/tor_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/tor_subscription.dart';

class SmallTorIcon extends ConsumerStatefulWidget {
  const SmallTorIcon({super.key});

  @override
  ConsumerState<SmallTorIcon> createState() => _SmallTorIconState();
}

class _SmallTorIconState extends ConsumerState<SmallTorIcon> {
  late TorConnectionStatus _status;

  Color _color(
    TorConnectionStatus status,
    StackColors colors,
  ) {
    switch (status) {
      case TorConnectionStatus.disconnected:
        return colors.textSubtitle3;

      case TorConnectionStatus.connected:
        return colors.accentColorGreen;

      case TorConnectionStatus.connecting:
        return colors.accentColorYellow;
    }
  }

  @override
  void initState() {
    _status = ref.read(pTorService).enabled
        ? TorConnectionStatus.connected
        : TorConnectionStatus.disconnected;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TorSubscription(
      onTorStatusChanged: (status) {
        setState(() {
          _status = status;
        });
      },
      child: AppBarIconButton(
        semanticsLabel: "Tor Settings Button. Takes To Tor Settings Page.",
        key: const Key("walletsViewTorButton"),
        size: 36,
        shadows: const [],
        color: Theme.of(context).extension<StackColors>()!.backgroundAppBar,
        icon: SvgPicture.asset(
          Assets.svg.tor,
          color: _color(
            _status,
            Theme.of(context).extension<StackColors>()!,
          ),
          width: 20,
          height: 20,
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(TorSettingsView.routeName);
        },
      ),
    );
  }
}
