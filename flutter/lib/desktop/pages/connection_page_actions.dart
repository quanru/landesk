part of 'connection_page.dart';

extension _ConnectionPageActions on _ConnectionPageState {
  Widget _connectionActions(BuildContext context) {
    final actionHeight =
        max(40.0, MediaQuery.textScalerOf(context).scale(14) + 20);
    return Padding(
      padding: const EdgeInsets.only(top: 13.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ConnectionActionButton(
          onPressed: () => onConnect(),
          label: translate("Connect"),
        ),
        const SizedBox(width: 8),
        Container(
          height: actionHeight,
          width: actionHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                var offset = Offset(0, 0);
                return Obx(() => InkWell(
                      child: _menuOpen.value
                          ? Transform.rotate(
                              angle: pi,
                              child: Icon(IconFont.more, size: 14),
                            )
                          : Icon(IconFont.more, size: 14),
                      onTapDown: (e) {
                        offset = e.globalPosition;
                      },
                      onTap: () async {
                        _menuOpen.value = true;
                        final x = offset.dx;
                        final y = offset.dy;
                        await mod_menu
                            .showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(x, y, x, y),
                          items: [
                            (
                              'Transfer file',
                              () => onConnect(isFileTransfer: true)
                            ),
                            (
                              'View camera',
                              () => onConnect(isViewCamera: true)
                            ),
                            (
                              '${translate('Terminal')} (beta)',
                              () => onConnect(isTerminal: true)
                            ),
                            // `connect` routes this through the
                            // desktop path only; the peer card gates
                            // it the same way.
                            if (isDesktop)
                              (
                                'TCP tunneling',
                                () => onConnect(isTcpTunneling: true)
                              ),
                          ]
                              .map<MenuEntryBase<String>>((e) =>
                                  MenuEntryButton<String>(
                                    childBuilder: (TextStyle? style) => Text(
                                      translate(e.$1),
                                      style: style,
                                    ),
                                    proc: () => e.$2(),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: kDesktopMenuPadding.left),
                                    dismissOnClicked: true,
                                  ))
                              .followedBy([
                                MenuEntryDivider<String>(),
                                _requestApprovalMenu(context),
                              ])
                              .map((e) => e.build(
                                  context,
                                  const MenuConfig(
                                      commonColor:
                                          CustomPopupMenuTheme.commonColor,
                                      height: CustomPopupMenuTheme.height,
                                      dividerHeight:
                                          CustomPopupMenuTheme.dividerHeight)))
                              .expand((i) => i)
                              .toList(),
                          elevation: 8,
                        )
                            .then((_) {
                          _menuOpen.value = false;
                        });
                      },
                    ));
              },
            ),
          ),
        ),
      ]),
    );
  }
}
