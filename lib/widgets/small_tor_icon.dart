import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../pages/settings_views/global_settings_view/tor_settings/tor_settings_view.dart';
import '../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../services/tor_service.dart';
import '../themes/stack_colors.dart';
import '../utilities/assets.dart';
import 'custom_buttons/app_bar_icon_button.dart';
import 'tor_subscription.dart';

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
    _status = ref.read(pTorService).status;

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
