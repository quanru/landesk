import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:flutter_hbb/models/peer_model.dart';

import '../../common.dart';
import '../../common/widgets/peer_tab_page.dart';
import '../../common/widgets/autocomplete.dart';
import '../../desktop/lan_discovery_refresh.dart';
import '../../models/model.dart';
import '../../models/platform_model.dart';
import 'home_page.dart';

/// Connection page for connecting to a remote peer.
class ConnectionPage extends StatefulWidget implements PageShape {
  ConnectionPage({Key? key, required this.appBarActions}) : super(key: key);

  @override
  final icon = const Icon(Icons.desktop_windows_outlined);

  @override
  final title = translate("Connection");

  @override
  final List<Widget> appBarActions;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

/// State for the connection page.
class _ConnectionPageState extends State<ConnectionPage>
    with WidgetsBindingObserver {
  /// Controller for the id input bar.
  final _idController = IDTextEditingController();
  final RxBool _idEmpty = true.obs;

  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberPassword = false;
  bool _showPassword = false;

  final AllPeersLoader _allPeersLoader = AllPeersLoader();

  StreamSubscription? _uniLinksSubscription;
  Timer? _discoveryTimer;

  // https://github.com/flutter/flutter/issues/157244
  Iterable<Peer> _autocompleteOpts = [];

  _ConnectionPageState() {
    if (!isWeb) _uniLinksSubscription = listenUniLinks();
    _idController.addListener(() {
      _idEmpty.value = _idController.text.isEmpty;
    });
    Get.put<IDTextEditingController>(_idController);
  }

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
    _idFocusNode.addListener(onFocusChanged);
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (lastRemoteId != _idController.id) {
          setState(() {
            _idController.id = lastRemoteId;
          });
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
    WidgetsBinding.instance.addObserver(this);
    _startDiscovery();
  }

  void _refreshPeers() {
    bind.mainLoadLanPeers();
    bind.mainLoadRecentPeers();
    bind.mainLoadFavPeers();
    bind.mainDiscover();
  }

  void _startDiscovery() {
    if (isWeb) return;
    _discoveryTimer?.cancel();
    _refreshPeers();
    _discoveryTimer = Timer.periodic(
      lanDiscoveryRefreshInterval,
      (_) => _refreshPeers(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startDiscovery();
    } else {
      _discoveryTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FfiModel>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 32, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                bottom: 4,
                              ),
                              child: Text(
                                translate('Connect'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _buildRemoteIDTextField(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    const Expanded(child: PeerTabPage()),
                  ],
                ),
              ),
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([_buildRemoteIDTextField()]),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: const PeerTabPage(),
            ),
          ],
        ).marginSymmetric(horizontal: 16);
      },
    );
  }

  /// Callback for the connect button.
  /// Connects to the selected peer.
  Future<void> onConnect({
    bool isFileTransfer = false,
    bool isViewCamera = false,
    bool isTerminal = false,
  }) async {
    final endpoint = _idController.id;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (endpoint.isEmpty || (username.isEmpty && password.isNotEmpty)) {
      showToast(
        '${translate('Local Address')} · ${translate('Username')} · ${translate('Password')}',
      );
      return;
    }
    await connect(
      context,
      endpoint,
      isFileTransfer: isFileTransfer,
      isViewCamera: isViewCamera,
      isTerminal: isTerminal,
      password: password.isEmpty
          ? null
          : jsonEncode({
              'lan_version': 1,
              'username': username,
              'password': password,
              'remember': _rememberPassword,
            }),
    );
    _passwordController.clear();
  }

  void onFocusChanged() {
    _idEmpty.value = _idEditingController.text.isEmpty;
    if (_idFocusNode.hasFocus) {
      if (_allPeersLoader.needLoad) {
        _allPeersLoader.getAllPeers();
      }

      final textLength = _idEditingController.value.text.length;
      // Select all to facilitate removing text, just following the behavior of address input of chrome.
      _idEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textLength,
      );
    }
  }

  /// UI for the remote endpoint field.
  /// Search for a peer and connect to it if the id exists.
  Widget _buildRemoteIDTextField() {
    final availableWidth = MediaQuery.sizeOf(context).width;
    final address = RawAutocomplete<Peer>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          _autocompleteOpts = const Iterable<Peer>.empty();
        } else if (_allPeersLoader.peers.isEmpty &&
            !_allPeersLoader.isPeersLoaded) {
          Peer emptyPeer = Peer(
            id: '',
            username: '',
            hostname: '',
            alias: '',
            platform: '',
            fingerprint: '',
            rdpPort: '',
            rdpUsername: '',
          );
          _autocompleteOpts = [emptyPeer];
        } else {
          String textWithoutSpaces = textEditingValue.text.replaceAll(" ", "");
          if (int.tryParse(textWithoutSpaces) != null) {
            textEditingValue = TextEditingValue(
              text: textWithoutSpaces,
              selection: textEditingValue.selection,
            );
          }
          String textToFind = textEditingValue.text.toLowerCase();

          _autocompleteOpts = _allPeersLoader.peers
              .where(
                (peer) =>
                    peer.id.toLowerCase().contains(textToFind) ||
                    peer.username.toLowerCase().contains(textToFind) ||
                    peer.hostname.toLowerCase().contains(textToFind) ||
                    peer.alias.toLowerCase().contains(textToFind),
              )
              .toList();
        }
        return _autocompleteOpts;
      },
      focusNode: _idFocusNode,
      textEditingController: _idEditingController,
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            updateTextAndPreserveSelection(
              fieldTextEditingController,
              _idController.text,
            );
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              onChanged: (text) => _idController.id = text,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '192.168.1.2',
                prefixIcon: const Icon(Icons.computer_outlined, size: 20),
                suffixIcon: IconButton(
                  tooltip: translate('Clear'),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _idController.clear()),
                ),
              ),
              inputFormatters: [IDTextInputFormatter()],
            );
          },
      onSelected: (option) {
        setState(() {
          _idController.id = option.id;
          FocusScope.of(context).unfocus();
        });
      },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<Peer> onSelected,
            Iterable<Peer> options,
          ) {
            options = _autocompleteOpts;
            double maxHeight = options.length * 50;
            if (options.length == 1) {
              maxHeight = 52;
            } else if (options.length == 3) {
              maxHeight = 146;
            } else if (options.length == 4) {
              maxHeight = 193;
            }
            maxHeight = maxHeight.clamp(0, 200);
            return Align(
              alignment: Alignment.topLeft,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Material(
                    elevation: 1,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                        maxWidth: (availableWidth - 24).clamp(200, 320),
                      ),
                      child:
                          _allPeersLoader.peers.isEmpty &&
                              !_allPeersLoader.isPeersLoaded
                          ? Container(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : ListView(
                              padding: EdgeInsets.only(top: 5),
                              children: options
                                  .map(
                                    (peer) => AutocompletePeerTile(
                                      onSelect: () => onSelected(peer),
                                      peer: peer,
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
    );
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label('IP'),
                address,
                const SizedBox(height: 18),
                label(translate('Username')),
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(),
                ),
                const SizedBox(height: 18),
                label(translate('Password')),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.go,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      tooltip: translate(_showPassword ? 'Hide' : 'Show'),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => onConnect(),
                ),
                if (isIOS)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CheckboxListTile(
                      value: _rememberPassword,
                      onChanged: (value) =>
                          setState(() => _rememberPassword = value == true),
                      title: Text(
                        translate('Remember password'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      contentPadding: EdgeInsets.zero,
                      tileColor: Colors.transparent,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  )
                else
                  const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => onConnect(),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(translate('Connect')),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final action in [
                      ('Transfer file', () => onConnect(isFileTransfer: true)),
                      ('View camera', () => onConnect(isViewCamera: true)),
                      ('Terminal', () => onConnect(isTerminal: true)),
                    ])
                      TextButton(
                        onPressed: action.$2,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        child: Text(translate(action.$1)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discoveryTimer?.cancel();
    _uniLinksSubscription?.cancel();
    _idController.dispose();
    _idFocusNode.removeListener(onFocusChanged);
    _allPeersLoader.clear();
    _idFocusNode.dispose();
    _idEditingController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }
}
