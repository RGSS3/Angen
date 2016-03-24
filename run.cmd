call android create project -k com.M3L.arious -t android-10 -p com/M3L/arious -a Arious
call android create avd -t android-10 -n com.M3L.arious -c 10M
cd com/M3L/arious
call keytool -genkey -alias hello -keystore main.keystore -storepass world! -keypass world! -keyalg RSA -validity 365
echo key.store=main.keystore>>local.properties
echo key.alias=hello>>local.properties
