require './angen.rb'
module A
  extend  Angen
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
         | type.OpenClass(WithThis)                             \
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
  
  class Expr
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
    def ==(rhs)
      Expr[BExpr[:==, self, rhs]]
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
        Expr[FCall[Var[a], args]]
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
      Expr.method_missing(:"#{A.output self}.#{sym}", *args)
    end
    def self.ffi(name, typeargs)
      t = Angen.T typeargs
      lambda{|*args, &b|
        raise TypeError, "in ffi #{name} #{t} #{args}" if !(t.===(*args))
        Var.from(Expr.js(name, *args), &b)
      }
    end
    def self.fun(&block)
      params = block.parameters.map{|x| x.last}.map{|x|
        x[0] == '_' ? x[1..-1] : x
      }
      r = yield(*params.map{|x| Expr[Var[x]]})      
      Expr[Fn[params, Expr[r].to_statement]]
    end
    
    def []=(a, b)
      self[a].assign b
    end
  end
  class Var
     @_id = 10000
    def self.from(rhs)
      name = begin
        x = Proc.new
        @_id += 1
        :"#{x.parameters[0].last}$#{@_id}"
      rescue 
        @_id += 1
        :"_var$#{@_id}"
      end
      Expr[VarA[name, rhs]] >> yield(Expr[Var[name]])
    end
    def self.call(rhs, &b)
      self.from(rhs, &b)
    end
    def self.let(rhs, &b) 
      self.from(rhs, &b)
    end
  end
  Console = Module.new do
    def self.method_missing(sym, *args)
      Expr.method_missing :"console.#{sym}", *args 
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
    when Do      then "#{expr.value[0].list.map{|x| (" "*(indent * 4)) + output(x, indent+1)}.join(";\n")}"
    when Fn      then "(function(#{expr.value[0].list.map{|x| output x, indent}.join(',')}){\n#{output Expr[expr.value[1]], indent + 1}\n#{" "*((indent)* 4)}})"
    when FCall   then "#{expr.value[0].value}(#{expr.value[1].list.map{|x| output x}.join(',')})"
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
         return "var #{var.value} = #{A.output expr}"
      }
    end  
  end
  a = Expr[BExpr[:+, 3, 5]]
  a.match(BExpr){|op, a, b|
    puts"#{a}:#{op}:#{b}"
  }.match(UExpr){|op, a|
    puts("#{a}:#{b}")
  }

 a = Console.log "Hello world"
 puts output a
 
 require = Expr.ffi :require, [Str]
 a = require.('fs') do |fs| fs.writeFileSync('1.txt', 'Hello world') end
 puts output a
end