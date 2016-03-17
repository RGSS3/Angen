require './angen.rb'
module A
  extend Angen
  extend Angen::Util
  extend Angen::MonadicEnv
  module WithThis
    def self.included(a)
      a.extend self
    end
    def classname a
      @name = a
    end
    def this
      Expr[:this]
    end
    def ret(a)
      Expr.ret(a)
    end
  end         
#---------TEST---------------------------------------------------------------
  Unary  = I(:+) | I(:-)
  Binary = I(:+) | I(:-) | I(:*) | I(:/) | I(:"=") | I(:==) | I(:".")
  Expr   = type.Num(Integer)                                            \
         | type.Str(String)                                             \
         | type.Var(Symbol)                                             \
         | type.Lam(Proc)                                               \
         | type.OpenClass(WithThis)                                     \
         | ctore.Arg(Num)                                               \
         | ctor.Do(list.Statements(rec.Expr))                           \
         | ctor.Fn(list.ArgList(rec.Expr), rec.Do)                      \
         | ctor.FCall(Var, ArgList)                                     \
         | ctor.UExpr(Unary,  rec.Expr)                                 \
         | ctor.BExpr(Binary, rec.Expr, rec.Expr)                       \
         | ctore.Ret(rec.Expr)                                          \
         | ctore.PExpr(rec.Expr)                                        \
         | ctor.VarA(Var, rec.Expr) 

# ------------- Impl -------------------------------------------------
  pushEnv Angen::MonadicEnv::Identity
  Extract = lambda{|x| env.extract(x)}
  Unbind  = lambda{|x| env.unbind(x)}
  
  module AutoEnv
    def method_added(sym)
      return if @__defining
      @__defining = true
      x = instance_method(sym)
      define_method sym do |*a, &b|
        Unbind[x.bind(Extract[self]).call(*a.map(&Extract))]
      end
      @__defining = false
    end
  end
  
  class Expr
    alias to_str inspect
    extend AutoEnv
    def +(rhs)
      Expr[BExpr[:+, self, rhs]]
    end
    def -(rhs)
      Expr[BExpr[:-, self, rhs]]
    end
    def *(rhs)
      Expr[BExpr[:*, self, rhs]]
    end
    def /(rhs)
      Expr[BExpr[:/, self, rhs]]
    end
    def eq(rhs)
      Expr[BExpr[:===, self, rhs]]
    end
    def assign(rhs)
      Expr[BExpr[:"=", self, rhs]]
    end
    def paren
      Expr[PExpr.unchecked(self)]
    end
    def self.ret(rhs)
      Expr[Do[Statements[[Ret.unchecked(rhs)]]]]
    end
    def >>(rhs)
      r = to_statement
      u = Expr[rhs].to_statement
      r._0.list += u._0.list
      Expr[r]
    end
    def self.fn(a)
      lambda{|*args|
        Unbind[Expr[FCall[Var[Extract[a]], args.map{|x| Extract[x]}]]]
      }
    end
    def self.def(fname)
      x = Proc.new
      args = x.parameters.map{|a| a.last}
      Expr[Do[Statements[[FDecl[fname, args, yield(*args.map{|x| Expr[x]}).to_statement]]]]]
    end
    def self.method_missing(sym, *args)      
      fn(sym).call(*args)
    end
    def self.js(sym, *args)
      fn(sym).call(*args)
    end
    
    def to_statement
      if Do === self.value
        r = self.value.clone
      else
        r = Do[Statements[[self]]]
      end      
      r
    end
    
    def [](rhs)
      Expr[BExpr[:'.', self, rhs]]
    end

    def method_missing(sym, *args)
      Expr.js(:"#{A.output self}.#{sym}", *args.map{|x| x})
    end
    def self.ffi(name, typeargs)
      t = Angen.T typeargs
      lambda{|*args, &b|
        raise TypeError, "in ffi #{name} #{t} #{args}" if !(t.===(*args))
        Var.from(Expr.js(name, *args))
      }
    end
    def self.fun(&block)
      params = block.parameters.map{|x| x.last}.map{|x|
        x[0] == '_' ? x[1..-1] : x
      }
      env = MyIdentity.new
      A.pushEnv env
      r = yield(*params.map{|x| Expr[Var[x]]})      
      re = Expr[Fn[params, Expr[env.result].to_statement]]
      A.popEnv
      re
    end
    
    def []=(a, b)
      self[a].assign b
    end
  end
  class Var
    @_id = 10000
    def self.from(rhs, name = nil)
      name ||= begin
        x = Proc.new
        @_id += 1
        :"#{x.parameters[0].last}$#{@_id}"
      rescue 
        @_id += 1
        :"_var$#{@_id}"
      end
      Unbind[Expr[VarA[name, Extract[rhs]]]]
      Expr[name]
    end
    def self.let(rhs, name = nil, &b) 
      self.from(rhs, name, &b)
    end
    def method_missing(sym, *args)
      if sym.to_s["="]
        r = sym.to_s.sub(/=/, "")
        Unbind[Expr[Extract[:"#{@path}.#{r}"]].assign(Extract[args[0]])]
      else
        if args.empty? && !block_given?
          Var[:"#{self.value}.#{sym}"]
        else
          Expr.js(:"#{self.value}.#{sym}", *args)
        end
      end
    end
  end

  Console = Module.new do
    def self.method_missing(sym, *args)
      Expr.js :"console.#{sym}", *args 
    end
    def self.log(*args)
      Expr.js :"console.log", *args
    end
  end
  
  
  def self.eliminate(u)
    while Ret === u
      u = u[0]
    end
    u
  end
  # 1

  def self.output(expr, indent = 0)
    case expr.value
    when Num,Var then "#{expr.value.value}"
    when Str     then "#{expr.value.value.inspect}"
    when Do      then "#{expr.value[0].list.map{|x| (" "*(indent * 4)) + output(x, indent)}.join(";\n")}"
    when Fn      then "(function(#{expr.value[0].list.map{|x| output x}.join(',')}){\n#{output Expr[expr.value[1]], indent + 1}\n#{" "*((indent )* 4)}})"
    when FCall   then "#{expr.value[0].value}(#{expr.value[1].list.map{|x|output x}.join(',')})"
    when UExpr   then "#{expr.value[0].value.value} #{output expr.value[1]}"
    when BExpr   then "#{output expr.value[1]}#{expr.value[0].value.value}#{output expr.value[2]}"
    when Ret     then "return #{output expr.value[0]}"      
    when PExpr   then "(#{output expr.value[0]})"
    when Lam     then output Expr.fun(&expr.value.value), indent 
    when OpenClass then
      klass = expr.value.value
      dummy = klass.new
      met = klass.instance_methods(false)
      name = klass.instance_eval{@name || to_s.split("::").last}
      "#{" "*(indent * 4)}var #{name} = #{name} || (function(){});\n" +
      met.map{|x|
        output(Expr[:"#{name}.prototype.#{x}"].assign(
          Expr.fun(&klass.instance_method(x).bind(dummy))
        ), indent + 1)
      }.join(";\n")
    else expr.value.output indent
    end
  end
  
  class VarA
    def output(indent = 0)
      match(VarA){|var, expr|
         return "var #{var.value} = #{A.output expr, indent}"
      }
    end  
  end
  
  class Local
    def [](sym)
      Expr[Var[sym]]
    end
    def []=(sym, exp)
      Expr[VarA[sym, Expr[exp]]]
    end
  end
  
  def self.local
    Local.new
  end
  
  class MyIdentity
    def initialize
      @things = []
    end
    def extract(a)
      @things.delete_if{|x| x.hash == a.hash}
      a
    end
    def unbind(a)
      @things << a unless @things.index{|x| x.hash == a.hash}
      a
    end
    def result
      @things.map{|x| Expr[x].rewrite(&method(:rewrite))}.inject(:>>)
    end
    def rewrite(a)
      a.match(Lam){|l|
        return Expr.fun(&l.value).rewrite(&method(:rewrite))
      }.match(Statements){|*u|      
        if !(Ret === u[-1].value)
          u[-1] = Expr[Ret.unchecked(u[-1])]
        end
        return u
      }
      a
    end
  end
  
  class Global
    def self.[]=(sym, a)
       Unbind[Expr[Extract[sym]].assign(Extract[a])]
    end
    def initialize(path)
      @path = path
    end
    
  end
  
  def self.run(&b)
    u = MyIdentity.new
    ";" + output(u.rewrite(Expr[Lam[b]])) + "();"
  end
  
  
  window = Var[:'window']
  puts run {
      a = Expr[3] + Expr[5]
      Console.log a
      a = Var.let ->x{
          a = Var.let ->x{
              a = Var.let ->x{
                  x + 1
              }
              x + 2
          }
           x + 2
      }
      Console.log a
      window.alert "Hello world"
  }

end