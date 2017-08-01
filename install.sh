#!/bin/sh

if [ "$1" = "" ]; then
	echo "Usage:   ./install.sh file.apk"
	exit 0
fi

echo "Enter Package Name:"
read -r packageName
echo "Enter Package File Name"
read -r packageFileName

uname=$(uname)
echo "OS type: $uname"

echo "Getting signature of $1..."
if [ "$uname" = "Darwin" ]; then
	sig=$(java -jar bin/GetAndroidSig.jar "$1" | grep "To char" | sed -E 's/^.{9}//')
else
	sig=$(java -jar bin/GetAndroidSig.jar "$1" | grep "To char" | sed -r 's/^.{9}//')
fi
echo "Signature: $sig"

echo "Backuping whitelist..."
adb shell "/data/local/tmp/rootme/su -c 'chmod 666 /data/data/whitelist-1.0.xml'"
adb shell "/data/local/tmp/rootme/su -c 'cp /data/data/whitelist-1.0.xml /data/local/tmp/'"
adb shell "/data/local/tmp/rootme/su -c 'chmod 666 /data/local/tmp/whitelist-1.0.xml'"
adb pull /data/local/tmp/whitelist-1.0.xml whitelist-1.0.xml

echo "Preparing replacement whitelist"
cat whitelist-1.0.xml | grep  -v "</applicationLists" | grep -v "</whiteList" > whitelist-1.0-new.xml

echo "        <application>
            <property>
                <name>$packageName</name>
                <package>$packageFileName</package>
                <versionCode>1-999999999</versionCode>
                <keyStoreLists> " >> whitelist-1.0-new.xml
#Need to handle case of sig containing multiple lines - some APKS have more than one sig

for signature in $sig; do
echo "                    <keyStore>$signature</keyStore> " >> whitelist-1.0-new.xml

done

echo "                </keyStoreLists>
            </property>
            <controlData>
                <withAudio>without</withAudio>
                <audioStreamType>null</audioStreamType>
                <regulation>null</regulation>
                <revert>no</revert>
            </controlData>
        </application>

	</applicationLists>
</whiteList>" >> whitelist-1.0-new.xml

if [ ! -z "$sig" ]; then
	echo "APK signature obtained"
else
	echo "Error: APK signature NOT obtained!"
	exit 1
fi

echo "Uploading whitelist to tmp..."
adb push whitelist-1.0-new.xml /data/local/tmp/whitelist-1.0-new.xml

adb shell "/data/local/tmp/rootme/su -c 'cat /data/local/tmp/whitelist-1.0-new.xml > /data/data/whitelist-1.0.xml'"
adb shell "/data/local/tmp/rootme/su -c 'chown system:system /data/data/whitelist-1.0.xml'"
adb install -r "$1"
#adb push $1 /data/local/tmp/$1
#adb shell "/data/local/tmp/rootme/su -c 'pm install -r /data/local/tmp/$1'"
