#!/bin/bash
export PATH=$PATH:$ANDROID_HOME/build-tools/29.0.3

SeeTemporaryFolder=false
Storepass=Pa$$wRd

if [ ! -f MainKeystore.keystore ]; then
    echo "Lets generate a keystore to sign your apk : "
    keytool -genkeypair -v -storetype pkcs12 -dname "cn=A, ou=B, o=C, c=D" -keystore MainKeystore.keystore -storepass $Storepass -alias MainKey -keyalg RSA -keysize 2048 -validity 10000
fi

echo "AAPT2"
mkdir -p gen bin
aapt2 compile -v --dir res/ -o res/res.zip
aapt2 compile -v --dir libs/constraint-layout-1.1.3-res -o libs/constraint-layout-1.1.3-res.zip
aapt2 link -v -I android.jar -R libs/constraint-layout-1.1.3-res.zip --auto-add-overlay --manifest src/AndroidManifest.xml --java gen/ --extra-packages android.support.constraint -o bin/AndroidTest.unsigned.unalign.apk res/res.zip 


if ! $SeeTemporaryFolder ; then
	rm -f libs/constraint-layout-1.1.3-res.zip
fi


for i in libs/*.jar; do
  libs="$libs:$i"
  dxlibs="$dxlibs $i"
  d8libs="$d8libs --classpath $i"
done
libs="${libs#:}"
all_java=$(find src gen -type f -name '*.java') #Find all R.java (from lib and src) and .java files

echo "JAVAC"
mkdir -p obj
javac -bootclasspath android.jar -d obj/ -classpath $libs -sourcepath src:gen $all_java

if ! $SeeTemporaryFolder ; then
	rm -fr gen/
fi

echo "D8"

all_class_file=$(find obj -type f) #Find all .class files generate by previous command
d8 --release $d8libs --lib android.jar --output bin/ $all_class_file $dxlibs

if ! $SeeTemporaryFolder ; then
	rm -fr obj/
fi
echo "ZIP"
zip -uj bin/AndroidTest.unsigned.unalign.apk bin/classes.dex 

echo "ZIPALIGN"

zipalign -vf 4 bin/AndroidTest.unsigned.unalign.apk bin/AndroidTest.unsigned.apk

echo "APKSIGNER"

apksigner sign  -v --ks MainKeystore.keystore --ks-key-alias MainKey --ks-pass pass:$Storepass --out bin/AndroidTest.apk bin/AndroidTest.unsigned.apk 

echo "ADB"

adb install -r bin/AndroidTest.apk
if ! $SeeTemporaryFolder ; then
	rm -fr bin/
fi