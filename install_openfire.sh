#!/bin/sh

# install_openfire.sh
# Installs the Openfire controller software on a FreeBSD machine (presumably running pfSense).

# The latest version of Openfire:
OPENFIRE_SOFTWARE_URL="http://www.igniterealtime.org/downloadServlet?filename=openfire/openfire_4_3_2.tar.gz"

# The rc script associated with this branch or fork:
RC_SCRIPT_URL="https://raw.githubusercontent.com/theagu/pfsense-openfire/master/rc.d/openfire.sh"


# If pkg-ng is not yet installed, bootstrap it:
if ! /usr/sbin/pkg -N 2> /dev/null; then
  echo "FreeBSD pkgng not installed. Installing..."
  env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg bootstrap
  echo " done."
fi

# If installation failed, exit:
if ! /usr/sbin/pkg -N 2> /dev/null; then
  echo "ERROR: pkgng installation failed. Exiting."
  exit 1
fi

# Determine this installation's Application Binary Interface
ABI=`/usr/sbin/pkg config abi`

# FreeBSD package source:
FREEBSD_PACKAGE_URL="https://pkg.freebsd.org/${ABI}/latest/All/"

# FreeBSD package list:
FREEBSD_PACKAGE_LIST_URL="https://pkg.freebsd.org/${ABI}/latest/packagesite.txz"

# Add the fstab entries apparently required for OpenJDKse:
if [ $(grep -c fdesc /etc/fstab) -eq 0 ]; then
  echo -n "Adding fdesc filesystem to /etc/fstab..."
  echo -e "fdesc\t\t\t/dev/fd\t\tfdescfs\trw\t\t0\t0" >> /etc/fstab
  echo " done."
fi

if [ $(grep -c proc /etc/fstab) -eq 0 ]; then
  echo -n "Adding procfs filesystem to /etc/fstab..."
  echo -e "proc\t\t\t/proc\t\tprocfs\trw\t\t0\t0" >> /etc/fstab
  echo " done."
fi

# Run mount to mount the two new filesystems:
echo -n "Mounting new filesystems..."
/sbin/mount -a
echo " done."

# Install required packages:

echo "Installing required packages..."
tar xv -C / -f /usr/local/share/pfSense/base.txz ./usr/bin/install
#uncomment below for pfSense 2.2.x:
#env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg install openjdk unzip pcre v8 snappy

fetch ${FREEBSD_PACKAGE_LIST_URL}
tar vfx packagesite.txz

AddPkg () {
 	pkgname=$1
 	pkginfo=`grep "\"name\":\"$pkgname\"" packagesite.yaml`
 	pkgvers=`echo $pkginfo | pcregrep -o1 '"version":"(.*?)"' | head -1`
	
	# compare version for update/install
 	if [ `pkg info | grep -c $pkgname-$pkgvers` -eq 1 ]; then
			echo "Package $pkgname-$pkgvers already installed."
		else
			env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg add -f ${FREEBSD_PACKAGE_URL}${pkgname}-${pkgvers}.txz
			
			# if update openjdk8 then force detele snappyjava to reinstall for new version of openjdk
			if [ "$pkgname" == "openjdk8" ]; then 
				env ASSUME_ALWAYS_YES=YES /usr/sbin/pkg delete snappyjava
			fi
		fi
}
	
AddPkg snappy
AddPkg cyrus-sasl
AddPkg xorgproto
AddPkg mkfontdir
AddPkg python2
AddPkg v8
AddPkg icu
AddPkg boost-libs
AddPkg unzip
AddPkg pcre
AddPkg alsa-lib
AddPkg freetype2
AddPkg fontconfig
AddPkg libXdmcp
AddPkg libpthread-stubs
AddPkg libXau
AddPkg libxcb
AddPkg libICE
AddPkg libSM
AddPkg java-zoneinfo
AddPkg libX11
AddPkg libXfixes
AddPkg libXext
AddPkg libXi
AddPkg libXt
AddPkg libfontenc
AddPkg mkfontscale
AddPkg mkfontdir
AddPkg dejavu
AddPkg libXtst
AddPkg libXrender
AddPkg libinotify
AddPkg javavmwrapper
AddPkg giflib
AddPkg openjdk8
AddPkg snappyjava

# Clean up downloaded package manifest:
rm packagesite.*

echo " done."

## OPENFIRE
echo -n "Downloading OpenFire"
/usr/bin/fetch -o openfire.tar.gz ${OPENFIRE_SOFTWARE_URL}

echo -n "Install Openfire"
mkdir /openfire
/usr/bin/tar -C / -zxpvf openfire.tar.gz


## Fetch the rc script from github:
echo -n "Installing rc script..."
/usr/bin/fetch -o /usr/local/etc/rc.d/openfire.sh ${RC_SCRIPT_URL}
echo " done."

## Fix permissions so it'll run
chmod +x /usr/local/etc/rc.d/openfire.sh
#
if [ ! -f /etc/rc.conf.local ] || [ $(grep -c openfire_enable /etc/rc.conf.local) -eq 0 ]; then
  echo -n "Enabling the openfire service..."
  echo "openfire_enable=YES" >> /etc/rc.conf.local
  echo " done."
fi

## Start it up:
echo -n "Starting the openfire service..."
/usr/sbin/service openfire.sh start
echo " done."