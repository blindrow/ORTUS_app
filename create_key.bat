@echo off
keytool -genkey -v -keystore android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass ortus2024 -keypass ortus2024 -dname "CN=ORTUS, OU=Mobile, O=ORTUS, L=Riga, ST=Latvia, C=LV"
