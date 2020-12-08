Basic Launcher
=======

Basic Launcher is an Android app to transfer RFO BASIC! programs (.bas) from your computer via WiFi or USB cable and run them on Android.
The Launcher app is written in RFO BASIC! with the GW library. It can be installed on all Android devices from Android 2.1 Eclair up to Android 10.

The Launcher is based on a fork version of RFO-BASIC! with added support for UDP broadcasting, detection of package (apps) installed on the system, and launch of a package app with an url parameter.
Search respectively for "UDP", "PKGEXIST" and "PKGLAUNCH" in src\com\rfo\BASICLauncher\Run.java

Basic Launcher source code is released under the GNU GPL v3 licence as per the attached file "gpl.txt". The licence can be found at https://www.gnu.org/licenses/gpl.txt

## Installing
Compile the project into an APK, copy it to your Android device and click on it to install it. You need to allow for third party installation on your device: see https://www.androidauthority.com/how-to-install-apks-31494/

## Dependencies
You will need to have a BASIC! variant on your device to run the transfered programs:
RFO-BASIC! Legacy (com.rfo.basic), RFO-BASIC! Reborn (com.rfo.Basic), OliBasic (com.rfo.basicTest/com.rfo.basicOli) or hbasic (com.rfo.basich/com.rfo.hbasic)

## Building
Basic Launcher can be compiled with any Android compiler, from the Android Command-Line tools to Android Studio, but we strongly recommend using the very simple [Android Xp Tools](http://mougino.free.fr/rfo-basic) from the same author.
