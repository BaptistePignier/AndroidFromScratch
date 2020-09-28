#!/bin/bash

#Replace by your own if needed
export PATH=$PATH:$ANDROID_HOME/build-tools/29.0.3
export PATH=$PATH:/opt/kotlinc/bin/

SeeTemporaryFolder=true

#Change if you whant but it's pointless
Storepass=Passwrd

echo "CLEANING"
rm -fr obj
rm -fr bin
rm -fr gen

#Create keystore if you dont have one
if [ ! -f MainKeystore.keystore ]; then
    echo "Lets generate a keystore to sign your apk : "
    keytool -genkeypair -v -storetype pkcs12 -dname "cn=A, ou=B, o=C, c=D" -keystore MainKeystore.keystore -storepass $Storepass -alias MainKey -keyalg RSA -keysize 2048 -validity 10000
fi

echo "AAPT2"
mkdir -p gen bin
aapt2 compile -v --dir res/ -o res/res.zip
aapt2 compile -v --dir libs/constraint-layout-1.1.3-res -o libs/constraint-layout-1.1.3-res.zip
aapt2 link -v -I android.jar -R libs/constraint-layout-1.1.3-res.zip  --auto-add-overlay --manifest src/AndroidManifest.xml --java gen/ --extra-packages android.support.constraint -o bin/AndroidTest.unsigned.unalign.apk res/res.zip 

#Find all usefull files
thereislibs=$(find libs -type f -name '*.jar')
if [ ! -z "thereislibs" ]; then
	for i in libs/*.jar; do
		libs="$libs:$i"
		dxlibs="$dxlibs $i"
		d8libs="$d8libs --classpath $i"
	done
	libs="${libs#:}"
fi

all_R_java=$(find gen -type f -name '*.java') #Find all R.java (from lib and src) and .java files
all_kotlin=$(find src -type f -name '*.kt')
all_code_java=$(find src -type f -name '*.java')




# Compile all .java file. If there is no java app's files, this will compile only R.java needed by d8 command
echo "JAVAC"
mkdir -p obj
if [ ! -z  "$thereislibs" ]; then
	#echo $libs
	javac -bootclasspath android.jar -d obj/ -classpath libs/recyclerview-v7-28.0.0.aar -sourcepath gen:src $all_R_java $all_code_java
else 
	javac -bootclasspath android.jar -d obj/ -sourcepath gen:src $all_R_java $all_code_java
fi


echo $all_kotlin
if [ ! -z "$all_kotlin" ] ; then
	echo "KOTLIN"
	kotlinc $all_kotlin $all_R_java -classpath $libs:android.jar -include-runtime -d obj/com/example/app/
fi

if ! $SeeTemporaryFolder ; then
	rm -fr gen/
fi

echo "D8"
jar cf obj/all.jar obj/

d8 --release --classpath recyclerview-v7-28.0.0.aar
 --lib android.jar --output bin/ obj/all.jar recyclerview-v7-28.0.0.aar
#$dxlibs

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