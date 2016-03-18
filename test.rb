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
  Unary  = I(:+) | I(:-) | I(:"!")
  Binary = I(:+) | I(:-) | I(:*) | I(:/) | I(:"=") | I(:==) | I(:".") | I(:">") | I(:"<") | I(:%) | I(:===)
  Expr   = type.Num(Integer)                                            \
         | type.Str(String)                                             \
         | type.Var(Symbol)                                             \
         | list.Arr(rec.Expr)                                           \
         | type.Tr(TrueClass)                                           \
         | type.Fa(FalseClass)                                          \
         | type.Lam(Proc)                                               \
         | type.OpenClass(WithThis)                                     \
         | ctore.Arg(Num)                                               \
         | ctor.Do(list.Statements(rec.Expr))                           \
         | ctore.Fn(list.ArgList(rec.Expr), rec.Do)                     \
         | ctore.Block(ArgList, rec.Do)                                 \
         | ctor.FCall(rec.Expr, ArgList)                                \
         | ctor.UExpr(Unary,  rec.Expr)                                 \
         | ctor.BExpr(Binary, rec.Expr, rec.Expr)                       \
         | ctore.Ret(rec.Expr)                                          \
         | ctore.PExpr(rec.Expr)                                        \
         | ctor.VarA(Var, rec.Expr)                                     \
         | ctor.If(rec.Expr,Block, optional.Block_(Block))              \
         | ctor.While(rec.Expr,Block)                                   \
         | ctor.For(rec.Expr, rec.Expr, rec.Expr, Block)                \
         | ctor.DoWhile(Block, rec.Expr)                                \
         | ctore.Break()                                                \
         | ctore.Continue()                                             \
         
         
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
        Unbind[x.bind(Extract[self]).call(*(a + Array(b)).map(&Extract))]
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
    def %(rhs)
      Expr[BExpr[:%, self, rhs]]
    end
    def >(rhs)
      Expr[BExpr[:>, self, rhs]]
    end
    def <(rhs)
      Expr[BExpr[:<, self, rhs]]
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
        Unbind[Expr[FCall[Extract[a], args.map{|x| Extract[x]}]]]
      }
    end
    def self.def(fname)
      x = Proc.new
      args = x.parameters.map{|a| a.last}
      Expr[Do[Statements[[FDecl[fname, args, yield(*args.map{|x| Expr[x]}).to_statement]]]]]
    end
    def self.method_missing(sym, *args, &b)      
      fn(sym).call(*(args + Array(b)))
    end
    def self.js(sym, *args, &b)
      fn(sym).call(*(args + Array(b)))
    end
    
    def not
      Expr[UExpr[:'!', Extract[self.paren]]]
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

    def method_missing(sym, *args, &b)
      Expr.js(:"#{A.output self, 0}.#{sym}", *args.map{|x| x})
    end
    def self.ffi(name, typeargs)
      t = Angen.T typeargs
      lambda{|*args, &b|
        raise TypeError, "in ffi #{name} #{t} #{args}" if !(t.===(*args))
        Var.from(Expr.js(name, *args))
      }
    end
    
    def call(*args, &block)
      Expr.js(self.paren, *(args + Array(block)).map{|x| x})
    end
    
    def self.if(expr, &block)
      Unbind[Expr[If[Extract[expr], Extract[self.blk(&block)].value, Angen::RootClass::N[] ]  ]  ]
    end
    
    def self.for(expr1, expr2, expr3, &block)
      Unbind[Expr[For[Extract[expr1], Extract[expr2], Extract[expr3], Extract[self.blk(&block)].value] ] ]
    end
    
    def else(block)
      self.value.match(If) do |expr, thenpart, elsepart|
        return Unbind[Expr[If[Extract[expr], Extract[thenpart], Block_[Extract[Expr.blk(&block)].value ]]  ]  ]
      end
      raise 'not an If statement'
    end
    
    def self.fun(&block)
      params = block.parameters.map{|x| x.last}.map{|x|
        x[0] == '_' ? x[1..-1] : x
      }
      env = MyIdentity.new
      A.pushEnv env
      r = yield(*params.map{|x| Expr[Var[x]]})      
      re = Expr[Fn.unchecked(params, Expr[env.result].to_statement)]
      A.popEnv
      re
    end
    
    def self.blk(&block)
      params = block.parameters.map{|x| x.last}.map{|x|
        x[0] == '_' ? x[1..-1] : x
      }
      env = MyIdentity.new
      A.pushEnv env
      r = yield(*params.map{|x| Expr[Var[x]]})      
      re = Expr[Block.unchecked(params, Expr[env.result].to_statement)]
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
    def method_missing(sym, *args, &b)
      if sym.to_s["="]
        r = sym.to_s.sub(/=/, "")
        Unbind[Expr[Extract[:"#{@path}.#{r}"]].assign(Extract[args[0]])]
      else
        if args.empty?
          if !block_given?
            Var[:"#{self.value}.#{sym}"]
          else
            Expr.js(:"#{self.value}.#{sym}", *(args+Array(b)))
          end
        else
          Expr.js(:"#{self.value}.#{sym}", *(args + Array(b)))
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

  def self.output(expr, indent)
    case expr.value
    when Num,Var, Tr, Fa then "#{expr.value.value}"
    when Str     then "#{expr.value.value.inspect}"
    when Do      then "#{expr.value[0].list.map{|x| (" "*(indent * 4)) + output(x, indent)}.join(";\n")}"
    when Fn      then "(function(#{expr.value[0].list.map{|x| output x, indent}.join(',')}){\n#{output Expr[expr.value[1]], indent + 1}\n#{" "*((indent)* 4)}})"
    when Block   then "{\n#{output Expr[expr.value[1]], indent + 1}\n#{" "*((indent)* 4)}}"
    when FCall   then "#{output expr.value[0], indent}(#{expr.value[1].list.map{|x|output x, indent}.join(',')})"
    when UExpr   then "#{expr.value[0].value.value} #{output expr.value[1], indent}"
    when BExpr   then "#{output expr.value[1], indent}#{expr.value[0].value.value}#{output expr.value[2], indent}"
    when Ret     then "return #{output expr.value[0], indent}"      
    when PExpr   then "(#{output expr.value[0], indent})"
    when Lam     then output Expr.fun(&expr.value.value), indent
    when Arr     then "[" + expr.value.list.map{|x| output x}.join(",") + "]" 
    when Break   then "break"
    when Continue   then "continue"
    when For     then
      expr.value.match(For) do |expr1, expr2, expr3, bl|
        return "for(#{output expr1, indent+1};#{output expr2, indent+1};#{output expr3, indent+1})#{output Expr[bl], indent + 1}"
      end  
    when If      then 
      a = "if(#{output expr.value[0], indent + 1}) #{output Expr[expr.value[1]], indent + 1}"
      expr.value[2].value.match(Angen::RootClass::N){
      }.match(Block){|arg, dost|
          a << "\n#{" "*(indent * 4)}else #{output Expr[Block.unchecked(arg, dost)], indent + 1}"
      }
      
      a
    
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
      }.match(Block) {|arg, blk|
        r = blk[0].list
        while Ret === r[-1].value
          r[-1] = r[-1].value[0]
        end
        return Block.unchecked(arg, blk) 
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
    ";" + output(u.rewrite(Expr[Lam[b]]), 0) + "();"
  end
  
  window = Var[:'window']
  class JSEnumerator
    def initialize(a)
      @a = a
    end
    def select(&b)
      JSEnumerator.new(lambda{|f| @a.call(
         lambda{|u| Expr.if(Expr[b].call(u)) {f.call u }} 
      )})
    end
    def take_while(&b)
      JSEnumerator.new(lambda{|f| @a.call(
         lambda{|u| Expr.if(Expr[Extract[b.call(Extract[u])]]) {f.call u }.else{ Unbind[Break.unchecked()]  }} 
      )})
    end
    def map(&b)
       JSEnumerator.new(lambda{|f| @a.call(
         lambda{|u| f.call(Expr[Extract[b.call(Extract[u])]]) } 
      )})
    end
    def drop_while(&b)
      JSEnumerator.new(lambda{|f| @a.call(
         lambda{|u| Expr.if(Expr[Extract[b.call(Extract[u])]]) {Unbind[Continue.unchecked()] }.else{ f.call u  }} 
      )})
    end
    def reduce(init = nil, &b)
      if init 
        result = Var.let init
        each{|v|
          result.assign(b.call(result, v))
        }
        result
      else
        first  = Var.let :true
        result = Var.let :null
        each{|v|
          Expr.if(first) {
            result.assign(v)
            first.assign(:false)
          }.else{
            result.assign(b.call(result, v))
          }
        }
        result
      end
    end
    
    
    
    def index(a = nil, &bl)
      result = Var.let 0
      each do |b|
        Expr.if(bl ? bl.call(b) : b == a) {
            Unbind[Break.unchecked()]
        } .else {
            result.assign(result + 1)
        }
      end  
      result
    end
    
    def count(a = nil, &bl)
      result = Var.let 0
      each do |b|
        Expr.if(bl ? bl.call(b) : b == a) {
            result.assign(result + 1)
        }
      end  
      result
    end
    
    def all?(&bl)
      result = Var.let :true
      each do |b|
        Expr.if(bl.call(b).not) {result.assign :false;  Unbind[Break.unchecked()]}
      end
      result
    end
    
     def any?(&bl)
      result = Var.let :false
      each do |b|
        Expr.if(bl.call(b).not) {result.assign :true;  Unbind[Break.unchecked()]}
      end
      result
    end
    
    
    def each(&b)
      @a.call(b)
    end
  end
  
  def self.range(a, b)
    JSEnumerator.new(lambda{|f| Expr.for(var = Var.let(a), var < b, var.assign(var + 1)) do f.call(var) end })
  end
  
  def self.iterate(a, b)
    JSEnumerator.new(lambda{|f| Expr.for(var = Var.let(a), Expr[:true], var.assign(b.call(var))) do f.call(var) end })
  end
  
  puts run {
    fs = Var.let Expr[:require].call('fs')
    fs.writeFile('::::', 'Hello world') do |err|
      Console.log err[:errno]
    end
  }

end