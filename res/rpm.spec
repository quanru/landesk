Name:       localdesk
Version:    1.3.0
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://github.com/quanru/localdesk
Vendor:     LocalDesk contributors
Requires:   gtk3 libxcb libXfixes alsa-lib libva2 pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3 libxdo

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/share/localdesk/
mkdir -p %{buildroot}/usr/share/localdesk/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/rustdesk %{buildroot}/usr/bin/localdesk
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/localdesk/libsciter-gtk.so
install $HBB/res/localdesk.service %{buildroot}/usr/share/localdesk/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/localdesk.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/localdesk.svg
install $HBB/res/rustdesk.desktop %{buildroot}/usr/share/localdesk/files/localdesk.desktop
install $HBB/res/rustdesk-link.desktop %{buildroot}/usr/share/localdesk/files/localdesk-link.desktop

%files
/usr/bin/localdesk
/usr/share/localdesk/libsciter-gtk.so
/usr/share/localdesk/files/localdesk.service
/usr/share/icons/hicolor/256x256/apps/localdesk.png
/usr/share/icons/hicolor/scalable/apps/localdesk.svg
/usr/share/localdesk/files/localdesk.desktop
/usr/share/localdesk/files/localdesk-link.desktop
/usr/share/localdesk/files/__pycache__/*

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
    rm /usr/share/applications/localdesk.desktop || true
    rm /usr/share/applications/localdesk-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
