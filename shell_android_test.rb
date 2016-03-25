require 'angen'
module Shell
  extend Angen
  extend Angen::Util
  extend Angen::MonadicEnv
  
  Extract = lambda{|x| env.extract(x)}
  Unbind  = lambda{|x| env.unbind(x)}
  Lift    = lambda{|x| env.lift(x)}
  class RewriteShell < Angen::MonadicEnv::StatementEnv
    def rewrite(a)
      a.match(Dict){|a|
        return rewrite(Opt[a.value.to_a])
      }.match(CreateProject){|a|
        r = nil 
        a.match(Opt){|list|
          r = rewrite(Args[list.flat_map{|x| [x._0, x._1]}])
          r.match(Args){ |list|
             return Command["call", ["android", "create", "project"] + list]
          }
        }
       
      }.match(CreateAVD){|a|
        r = nil 
        a.match(Opt){|list|
          r = rewrite(Args[list.flat_map{|x| [x._0, x._1]}])
          r.match(Args){ |list|
            return Command["call", ["android", "create", "avd"] + list]
          }
        }
      }.match(ListTarget){
        return Command["call", ["android", "list", "target"]]
      }
      a
    end
  end
  
  class Run < RewriteShell
    def lift(x)
      ShellRun[[x]]
    end
  end
  
  class Show < RewriteShell
    def lift(x)
      ShellShow[[x]]
    end
  end
  
  type.Str  String
  type.Dict Hash
  list.Opt A [Str, Str]
  ctor.CreateProject Opt
  ctor.ListTarget
  Android  = CreateProject | ListTarget | rec.Command | ctor.CreateAVD(Opt)
  Shell    = ctor.Command(Str, list.Args(Str))  | rec.Android
             
  list.ShellRun  Shell
  list.ShellShow Shell
  
  class Shell 
    def >>(rhs)
      Lift[self] >> rhs
    end
    alias statement_append_ >>
    def output
      value.output
    end
  end
  
  class Command
    def output
      match(Command) do |str, args|
        return "#{str.output} #{args.output}"
      end
    end
  end
  
  class Android
    def output
      self.value.output
    end
  end
  
  class ShellRun
    def >>(rhs)
      rhs.match(ShellRun){|a|
        return ShellRun[list + a]
      }.match(Shell){|a|
        return ShellRun[list + [rhs]]
      }
    end
     alias statement_append_ >>
  end
  
  class ShellShow
    def >>(rhs)
      rhs.match(ShellShow){|a|
        return ShellShow[list + a]
      }.match(Shell){|a|
        return ShellShow[list + [rhs]]
      }
    end
     alias statement_append_ >>
  end
  
  class Args
    def output
     match(Args) do |*args|     
       return args.map{|x| x.map(&:output)}.join(' ')
     end
    end
  end
  
  
  
  class Str
    def output
      if (self.value[' '] || self.value['"']) && !(self.value =~ /^"[^"]*"$/) 
        self.value.inspect
      else
        self.value
      end
    end
  end
  
  def self.sh(a)
    Unbind[a]
  end
  
  def self.command(a, *b)
    Command[a, Args[b]]
  end
   
  def self.tree(&b)
    x = const_get((b.parameters[0] || ["", "Run"]).last.capitalize)
    pushEnv x.new
    class_eval &b
    popEnv
  end
  
  def self.runShell(&b)
    r = tree(&b).result
     open "run.cmd", "w" do |f|
        r.list.each{|x|
        f.write x.output
        f.write "\n"
      } 
    end    
    r.match(ShellRun){|a|
      system "run.cmd"
    }.match(ShellShow){|a|
      system "type run.cmd"
    }
  end
  
  
  def self.rubyeval(a)
    sh command "ruby", "-e", a
  end
  
  def self.genkey(als, pass, file = "main.keystore", alg = "RSA", validity = "365")
    Unbind[Command["call", ["keytool", "-genkey", "-alias", als, "-keystore", file, "-storepass", pass, "-keypass", pass, "-keyalg", alg, "-validity", validity]]]
    appendLine    "local.properties", "key.store=#{file}"
    appendLine    "local.properties", "key.alias=#{als}"     
  end
  
   def self.genavd(name , target, size = "10M")
    Unbind[CreateAVD[[["-t", target], ["-n", name], ["-c", size.to_s]]]]
  end
  def self.createProject(package, activity = package.split(".").last.capitalize, target = "android-10", path = package.tr(".", "/"))
    Unbind[CreateProject[[["-k", package], ["-t", target], ["-p", path], ["-a", activity]]]]
    genavd package, target
  end
  
  def self.listTarget
    Unbind[ListTarget[]]
  end
  
  def self.define_shell(a)
    (class << self; self; end).send :define_method, a do |*args|
      sh command a.to_s, *args
    end
  end 
  
  def self.appendLine(a, b)
     Unbind[Command["echo", [b + ">>" + a]]]
  end
  
  define_shell :cd
  define_shell :ant
  define_shell :adb
end


