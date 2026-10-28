import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/peer_tab_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../../models/favorite_group_model.dart';
import '../../models/peer_model.dart';
import '../../models/platform_model.dart';
import 'peer_card.dart';
import 'device_empty_state.dart';
import 'responsive_layout.dart';

typedef PeerFilter = bool Function(Peer peer);
typedef PeerCardBuilder = Widget Function(Peer peer);

class PeerSortType {
  static const String endpoint = 'Endpoint';
  static const String remoteHost = 'Remote Host';
  static const String username = 'Username';
  static const String status = 'Status';

  static List<String> values = [
    PeerSortType.endpoint,
    PeerSortType.remoteHost,
    PeerSortType.username,
    PeerSortType.status
  ];
}

class LoadEvent {
  static const String recent = 'load_recent_peers';
  static const String favorite = 'load_fav_peers';
  static const String lan = 'load_lan_peers';
}

class PeersModelName {
  static const String recent = 'recent peer';
  static const String favorite = 'fav peer';
  static const String lan = 'discovered peer';
}

/// for peer search text, global obs value
final peerSearchText = "".obs;

/// for peer sort, global obs value
RxString? _peerSort;
RxString get peerSort {
  _peerSort ??= bind.getLocalFlutterOption(k: kOptionPeerSorting).obs;
  return _peerSort!;
}

// list for listener
RxList<RxString> get obslist => [peerSearchText, peerSort].obs;

final peerSearchTextController =
    TextEditingController(text: peerSearchText.value);

class _PeersView extends StatefulWidget {
  final Peers peers;
  final PeerFilter? peerFilter;
  final PeerCardBuilder peerCardBuilder;
  final PeerTabIndex peerTabIndex;

  const _PeersView(
      {required this.peers,
      required this.peerCardBuilder,
      required this.peerTabIndex,
      this.peerFilter,
      Key? key})
      : super(key: key);

  @override
  _PeersViewState createState() => _PeersViewState();
}

/// State for the peer widget.
class _PeersViewState extends State<_PeersView> {
  final space = (isDesktop || isWebDesktop) ? 12.0 : 8.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We should avoid too many rebuilds. MacOS(m1, 14.6.1) on Flutter 3.19.6.
    // Continious rebuilds of `ChangeNotifierProvider` will cause memory leak.
    // Simple demo can reproduce this issue.
    return ChangeNotifierProvider<Peers>.value(
      value: widget.peers,
      child: Consumer<Peers>(builder: (context, peers, child) {
        if (peers.peers.isEmpty) {
          gFFI.peerTabModel.setCurrentTabCachedPeers([]);
          final chinese = Localizations.localeOf(context).languageCode == 'zh';
          final (title, description, icon) = switch (widget.peers.loadEvent) {
            LoadEvent.lan => (
              chinese ? '尚未发现设备' : 'No devices discovered yet',
              chinese ? '确认另一台电脑已开启 landesk，并连接到同一网络。你也可以通过 IP 地址连接。'
                  : 'Open landesk on another computer on the same network. You can also connect using its IP address.',
              Icons.devices_outlined,
            ),
            LoadEvent.recent => (
              chinese ? '还没有连接记录' : 'No recent connections',
              chinese ? '连接过的设备会显示在这里，方便下次访问。'
                  : 'Devices you connect to will appear here for quick access next time.',
              Icons.history_rounded,
            ),
            _ => (
              chinese ? '还没有收藏设备' : 'No favorites yet',
              chinese ? '收藏常用设备，下次就能更快找到它们。'
                  : 'Add your frequently used devices to favorites to find them quickly.',
              Icons.star_border_rounded,
            ),
          };
          return DeviceEmptyState(title: title, description: description, icon: icon);
        } else {
          return _buildPeersView(peers);
        }
      }),
    );
  }

  Widget _buildPeersView(Peers peers) {
    final body = ObxValue<RxList>((filters) {
      return FutureBuilder<List<Peer>>(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var peers = snapshot.data!;
            if (peers.length > 1000) peers = peers.sublist(0, 1000);
            gFFI.peerTabModel.setCurrentTabCachedPeers(peers);
            if (peers.isEmpty) {
              final chinese = Localizations.localeOf(context).languageCode == 'zh';
              final searching = filters[0].value.trim().isNotEmpty;
              return DeviceEmptyState(
                icon: searching ? Icons.search_off_rounded : Icons.folder_outlined,
                title: searching
                    ? (chinese ? '没有匹配的设备' : 'No matching devices')
                    : (chinese ? '这里还没有设备' : 'No devices here yet'),
                description: searching
                    ? (chinese ? '试试其他设备名称或 IP 地址，或清除搜索查看全部设备。'
                        : 'Try another device name or IP address, or clear the search to see all devices.')
                    : (chinese ? '切换列表或分组查看其他设备。'
                        : 'Choose another list or group to see other devices.'),
                actionLabel: searching ? (chinese ? '清除搜索' : 'Clear search') : null,
                onAction: searching ? () {
                  peerSearchTextController.clear();
                  peerSearchText.value = '';
                } : null,
              );
            }

            buildOnePeer(Peer peer, bool isPortrait) {
              final peerCard = widget.peerCardBuilder(peer);
              // `Provider.of<PeerTabModel>(context)` will causes infinete loop.
              // Because `gFFI.peerTabModel.setCurrentTabCachedPeers(peers)` will trigger `notifyListeners()`.
              //
              // No need to listen the currentTab change event.
              // Because the currentTab change event will trigger the peers change event,
              // and the peers change event will trigger _buildPeersView().
              return !isPortrait
                  ? Obx(() => peerCardUiType.value == PeerUiType.list
                      ? Container(constraints: const BoxConstraints(minHeight: 64), child: peerCard)
                      : peerCardUiType.value == PeerUiType.grid
                          ? SizedBox.expand(child: peerCard)
                          : SizedBox(width: 220, height: 42, child: peerCard))
                  : Container(child: peerCard);
            }

            // We should avoid too many rebuilds. Win10(Some machines) on Flutter 3.19.6.
            // Continious rebuilds of `ListView.builder` will cause memory leak.
            // Simple demo can reproduce this issue.
            final Widget child = Obx(() => shouldUseCompactPeerLayout(
                    isMobilePlatform: isMobile,
                    isWebMobile: isWeb && !isWebDesktop,
                    isPortrait: stateGlobal.isPortrait.isTrue)
                ? ListView.builder(
                    itemCount: peers.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildOnePeer(peers[index], true).marginOnly(
                          top: index == 0 ? 0 : space / 2, bottom: space / 2);
                    },
                  )
                : peerCardUiType.value == PeerUiType.list
                    ? ListView.builder(
                        controller: _scrollController,
                        itemCount: peers.length,
                        itemBuilder: (BuildContext context, int index) {
                          return buildOnePeer(peers[index], false).marginOnly(
                              right: space,
                              top: index == 0 ? 0 : space / 2,
                              bottom: space / 2);
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columnCount =
                              ((constraints.maxWidth + space) / (220 + space))
                                  .floor()
                                  .clamp(1, 6)
                                  .toInt();
                          final cardWidth = (constraints.maxWidth -
                                  space * (columnCount - 1)) /
                              columnCount;
                          final extraTextHeight =
                              (MediaQuery.textScalerOf(context).scale(14) - 14)
                                  .clamp(0, 28);
                          return GridView.builder(
                            controller: _scrollController,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columnCount,
                              mainAxisSpacing: space,
                              crossAxisSpacing: space,
                              childAspectRatio:
                                  cardWidth / (270 + extraTextHeight * 7),
                            ),
                            itemCount: peers.length,
                            itemBuilder: (BuildContext context, int index) {
                              return buildOnePeer(peers[index], false);
                            },
                          );
                        },
                      ));

            return child;
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
        future: matchPeers(filters[0].value, filters[1].value, peers.peers),
      );
    }, obslist);

    return body;
  }

  Future<List<Peer>>? matchPeers(
      String searchText, String sortedBy, List<Peer> peers) async {
    if (widget.peerFilter != null) {
      peers = peers.where((peer) => widget.peerFilter!(peer)).toList();
    }

    // fallback to id sorting
    if (!PeerSortType.values.contains(sortedBy)) {
      sortedBy = PeerSortType.endpoint;
      bind.setLocalFlutterOption(
        k: kOptionPeerSorting,
        v: sortedBy,
      );
    }

    if (widget.peers.loadEvent != LoadEvent.recent ||
        sortedBy == PeerSortType.status) {
      switch (sortedBy) {
        case PeerSortType.endpoint:
          peers.sort((p1, p2) => p1.getId().compareTo(p2.getId()));
          break;
        case PeerSortType.remoteHost:
          peers.sort((p1, p2) =>
              p1.hostname.toLowerCase().compareTo(p2.hostname.toLowerCase()));
          break;
        case PeerSortType.username:
          peers.sort((p1, p2) =>
              p1.username.toLowerCase().compareTo(p2.username.toLowerCase()));
          break;
        case PeerSortType.status:
          peers.sort(comparePeerStatus);
          break;
      }
    }

    searchText = searchText.trim();
    if (searchText.isEmpty) {
      return peers;
    }
    searchText = searchText.toLowerCase();
    final matches = await Future.wait(
        peers.map((peer) => matchPeer(searchText, peer, widget.peerTabIndex)));
    final filteredList = List<Peer>.empty(growable: true);
    for (var i = 0; i < peers.length; i++) {
      if (matches[i]) {
        filteredList.add(peers[i]);
      }
    }

    return filteredList;
  }
}

abstract class BasePeersView extends StatelessWidget {
  final PeerTabIndex peerTabIndex;
  final PeerFilter? peerFilter;
  final PeerCardBuilder peerCardBuilder;

  const BasePeersView({
    Key? key,
    required this.peerTabIndex,
    this.peerFilter,
    required this.peerCardBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Peers peers;
    switch (peerTabIndex) {
      case PeerTabIndex.recent:
        peers = gFFI.recentPeersModel;
        break;
      case PeerTabIndex.fav:
        peers = gFFI.favoritePeersModel;
        break;
      case PeerTabIndex.lan:
        peers = gFFI.lanPeersModel;
        break;
    }
    return _PeersView(
        peers: peers,
        peerFilter: peerFilter,
        peerCardBuilder: peerCardBuilder,
        peerTabIndex: peerTabIndex);
  }
}

class RecentPeersView extends BasePeersView {
  RecentPeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.recent,
          peerCardBuilder: (Peer peer) => RecentPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadRecentPeers();
    return widget;
  }
}

class FavoritePeersView extends BasePeersView {
  FavoritePeersView(
      {Key? key,
      EdgeInsets? menuPadding,
      ScrollController? scrollController,
      String? groupId})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.fav,
          peerFilter: groupId == null
              ? null
              : (Peer peer) => favoriteGroupModel.matches(peer.id, groupId),
          peerCardBuilder: (Peer peer) => FavoritePeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    bind.mainLoadFavPeers();
    return widget;
  }
}

class DiscoveredPeersView extends BasePeersView {
  DiscoveredPeersView(
      {Key? key, EdgeInsets? menuPadding, ScrollController? scrollController})
      : super(
          key: key,
          peerTabIndex: PeerTabIndex.lan,
          peerCardBuilder: (Peer peer) => DiscoveredPeerCard(
            peer: peer,
            menuPadding: menuPadding,
          ),
        );

  @override
  Widget build(BuildContext context) {
    final widget = super.build(context);
    if (!isDesktop) {
      bind.mainLoadLanPeers();
      bind.mainDiscover();
    }
    return widget;
  }
}
