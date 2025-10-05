# Maintainer: Your Name <your.email@example.com>

pkgname=steamdeck-power-manager
pkgver=1.0.0
pkgrel=1
pkgdesc="An autonomous power management system for the Steam Deck that intelligently monitors and controls power usage to extend battery life during gaming sessions"
arch=('any')
url="https://github.com/yourusername/steamdeck-power-manager"
license=('MIT')
depends=('python' 'python-psutil')
makedepends=('git')
optdepends=('radeontop: for more accurate GPU usage monitoring')
backup=('etc/steamdeck-power-manager/config.json')
install=steamdeck-power-manager.install

source=("${pkgname}-${pkgver}.tar.gz::https://github.com/yourusername/steamdeck-power-manager/archive/v${pkgver}.tar.gz")
sha256sums=('SKIP') # Replace with actual hash after creating the tarball

package() {
    cd "${srcdir}/${pkgname}-${pkgver}"
    
    # Create directories
    install -dm755 "${pkgdir}/usr/lib/steamdeck-power-manager/"
    install -dm755 "${pkgdir}/etc/steamdeck-power-manager/"
    install -dm755 "${pkgdir}/etc/systemd/system/"
    install -dm755 "${pkgdir}/usr/bin/"
    
    # Install Python modules
    cp -r steamdeck_power_manager/core "${pkgdir}/usr/lib/steamdeck-power-manager/"
    cp -r steamdeck_power_manager/control "${pkgdir}/usr/lib/steamdeck-power-manager/"
    cp -r steamdeck_power_manager/utils "${pkgdir}/usr/lib/steamdeck-power-manager/"
    cp steamdeck_power_manager/__init__.py "${pkgdir}/usr/lib/steamdeck-power-manager/"
    
    # Install systemd services
    install -m644 steamdeck_power_manager/service/steamdeck-power-manager-monitor.service "${pkgdir}/etc/systemd/system/"
    install -m644 steamdeck_power_manager/service/steamdeck-power-manager-control.service "${pkgdir}/etc/systemd/system/"
    
    # Install config
    install -m644 steamdeck_power_manager/config/default_config.json "${pkgdir}/etc/steamdeck-power-manager/config.json"
    
    # Install wrapper script
    install -m755 steamdeck-power-manager.sh "${pkgdir}/usr/bin/"
}

# vim:set ts=2 sw=2 et: