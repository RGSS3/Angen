require 'shell_android_test'
require 'java_android_test'
PACKAGE = "com.M3L.arious"
DIR     = PACKAGE.tr ".", "/"
FILE    = "#{DIR}/src/#{DIR}/Arious.java"
APK     = "#{DIR}/bin/Arious-Release.apk"
task :init do 
  Shell::runShell{|run|
    createProject PACKAGE
    cd            DIR
    genkey        "hello", "world!"
  }
end
task :edit do 
  Java.write PACKAGE, FILE do
    import_android "app", "os", "widget"
      activity("arious"){
        onCreate{|_super, _this, saved| 
          _super.onCreate saved
          ns.Toast.makeText(_this.getApplicationContext, 
                            "Hello world", 
                            1000).
          show  
        }
      }
  end
end
task :compile => APK
file APK => FILE  do 
  Shell::runShell{|run|
    cd   DIR
    ant "release"
  }
end