# Angen
Ange for Another Generator. 


Current Test Instructions
-------------
Requirements:
* Win32 Env
* ADK
* Ant
* JDK

```rake -f test_rake.rb -I . init```
=> generate an Android App skeleton using ADK along with an AVD and a keystore
```rake -f test_rake.rb -I . edit```
=> generate App UI (res/layout/main.xml) and Main logic (src/Arious.java)
```rake -f test_rake.rb -I . compile```
=> generate APK



