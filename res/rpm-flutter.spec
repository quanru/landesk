Name:       localdesk
Version:    1.3.0
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://github.com/quanru/localdesk
Vendor:     LocalDesk contributors
Requires:   gtk3 libxcb libXfixes alsa-lib libva pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3 libxdo
Provides:   libdesktop_drop_plugin.so()(64bit), libdesktop_multi_window_plugin.so()(64bit), libfile_selector_linux_plugin.so()(64bit), libflutter_custom_cursor_plugin.so()(64bit), libflutter_linux_gtk.so()(64bit), libscreen_retriever_plugin.so()(64bit), libtray_manager_plugin.so()(64bit), liburl_launcher_linux_plugin.so()(64bit), libwindow_manager_plugin.so()(64bit), libwindow_size_plugin.so()(64bit), libtexture_rgba_renderer_plugin.so()(64bit)

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

# %global __python %{__python3}

%install

mkdir -p "%{buildroot}/usr/share/localdesk" && cp -r ${HBB}/flutter/build/linux/x64/release/bundle/* -t "%{buildroot}/usr/share/localdesk"
mkdir -p "%{buildroot}/usr/bin"
install -Dm 644 $HBB/res/localdesk.service -t "%{buildroot}/usr/share/localdesk/files"
install -Dm 644 $HBB/res/rustdesk.desktop "%{buildroot}/usr/share/localdesk/files/localdesk.desktop"
install -Dm 644 $HBB/res/rustdesk-link.desktop "%{buildroot}/usr/share/localdesk/files/localdesk-link.desktop"
install -Dm 644 $HBB/res/128x128@2x.png "%{buildroot}/usr/share/icons/hicolor/256x256/apps/localdesk.png"
install -Dm 644 $HBB/res/scalable.svg "%{buildroot}/usr/share/icons/hicolor/scalable/apps/localdesk.svg"

%files
/usr/share/localdesk/*
/usr/share/localdesk/files/localdesk.service
/usr/share/icons/hicolor/256x256/apps/localdesk.png
/usr/share/icons/hicolor/scalable/apps/localdesk.svg
/usr/share/localdesk/files/localdesk.desktop
/usr/share/localdesk/files/localdesk-link.desktop

%changelog
# let's skip this for now

%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop localdesk || true
  ;;
esac

%post
cp /usr/share/localdesk/files/localdesk.service /etc/systemd/system/localdesk.service
cp /usr/share/localdesk/files/localdesk.desktop /usr/share/applications/
cp /usr/share/localdesk/files/localdesk-link.desktop /usr/share/applications/
ln -sf /usr/share/localdesk/localdesk /usr/bin/localdesk
systemctl daemon-reload
systemctl enable localdesk
systemctl start localdesk
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop localdesk || true
    systemctl disable localdesk || true
    rm /etc/systemd/system/localdesk.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/bin/localdesk || true
    rmdir /usr/share/localdesk || true
    rm /usr/share/applications/localdesk.desktop || true
    rm /usr/share/applications/localdesk-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
