require 'shell_android_test'
require 'java_android_test'
require 'layout.rb'
PACKAGE = "com.M3L.arious"
DIR     = PACKAGE.tr ".", "/"
FILE    = "#{DIR}/src/#{DIR}/Arious.java"
APK     = "#{DIR}/bin/Arious-Release.apk"
LAYOUT  = "#{DIR}/res/layout/main.xml"
task :init do 
  Shell::runShell{|run|
    createProject PACKAGE
    cd            DIR
    genkey        "hello", "world!"
  }
end
task :edit do

   
  Java.write PACKAGE, FILE do
    Control = lambda{|type, id|lambda{let type, Java::Expr[:this].findViewById(Java::Expr.static :R, :id, id).cast(type), [:final]}}
    btn = {};button = lambda{|*a|id = Layout.hbutton(*a);btn[a[0]] = Control[:Button, id];id};textEdit = nil
    Layout.write LAYOUT do
       topnode(:vertical, :layout_width => "match_parent", :layout_height => "match_parent") do
            horizontal{textEdit = Control[:EditText, htext("")] }
            ["789+", "456-", "123*", "0.=/"].each{|x| horizontal{x.split("").each{|y| button[y]}}}
            horizontal{ button["AC", 2]; button["CE", 2];}
            horizontal{["M+", "M-", "MR", "MC"].each{|x| button[x]   } }
       end
    end
    import_android "app", "os", "widget", "view", "view.View"
    activity("arious"){
        state, op, last, flt, op2, eqpress, mem = let(:Boolean, :true), let(:int, 0), let(:float, 0), Java::Expr[:Float], let(:float, 0), let(:Boolean, false), let(:float, 0)
        onCreate{|_super, _this, saved| 
          _super.onCreate saved;_this.setContentView(Java::Expr.static(:R, :layout, :main))
          t = textEdit[];
          addtext = lambda{|x| t.getText.append(x)};settext = lambda{|x| t.getText.clear; t.getText.append(x) };gettext = t.getText.toString
          btn.each{|k, v|
           v.().setOnClickListener onClickListener{|w|
            if(k[/\d|\./])
              Java::Expr.if(state){settext[k]; state.java_value = false}.else{addtext[k]}; eqpress.java_value = false
           elsif (r = "+-*/".index(k))
              op.java_value, last.java_value, state.java_value = r, flt.parseFloat(gettext), true; eqpress.java_value = false
           elsif k == "="
              Java::Expr.if(eqpress.not){op2.java_value = flt.parseFloat(gettext)}
              "+-*/".split("").each_with_index{|x, i| Java::Expr.if(op.eq i){ last.java_value = last.send(x, op2); settext[flt.toString(last)]}}
              state.java_value = true
              eqpress.java_value = true
           elsif k == "AC"
              settext[""]
              state.java_value = true
              eqpress.java_value = false
              op.java_value = 0
           elsif k == "CE"
              settext[""]
              state.java_value = true
           elsif k == "M+" then  mem.java_value += flt.parseFloat(gettext)
           elsif k == "M-" then  mem.java_value -= flt.parseFloat(gettext)
           elsif k == "MR" then  settext[flt.toString(mem)]
           elsif k == "MC" then  mem.java_value = 0 
           end
           }
          }
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

task :reinstall do 
 Shell.runShell{|run|
  adb "uninstall", PACKAGE
  adb "install", APK, ENV["emulator"]
 }
end
