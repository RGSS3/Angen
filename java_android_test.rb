require 'angen'
module Java
  extend Angen
  extend Angen::Util
  extend Angen::MonadicEnv
  
  Extract = lambda{|x| env.extract(x)}
  Unbind  = lambda{|x| env.unbind(x)}
  Lift    = lambda{|x| env.lift(x)}
  pushEnv Angen::MonadicEnv::Identity
  class Rewriter < Angen::MonadicEnv::StatementEnv
    def rewrite(a)
      a
    end
    def lift(x)
      Expr[x]
    end
  end
  indent_size = 0
  Indent = lambda{|&b|
        begin
            r = b.call
            return r.split("\n").map{|x| "  " + x }.join("\n")
        ensure
        
        end
  }                            
           
  def self.def_out(*klasses, &b)
    
    klasses.each{|klass|
      if klass < Angen::RootClass::U
        klass.send :define_method, :output do
          value.output
        end
      elsif klass < Angen::RootClass::T || klass < Angen::RootClass::A 
        klass.send :define_method, :output do
          match(klass) do |*a| return instance_exec(*a, &b) end
        end
      elsif klass < Angen::RootClass::I
        klass.send :define_method, :output do
          instance_exec &b
        end
       elsif klass < Angen::RootClass::L
        klass.send :define_method, :output do
          instance_exec list, &b
        end
      end
    }
  end
 
#--------------LANGUAGE-------------------------------------------------------------
    
  type.Str   String
  type.Int   Integer
  type.Flt   Float
  type.Ident Symbol
  type.BinOp(/[\+\-\*\/%^&|\.]|\|\||\&\&|>|<|>=|<=|==|!=|>>|<</)
  type.PrefixUnOp(/[\+\-]|\+\+|--|!|~/)
  type.SuffixUnOp(/\+\+|--/)
  ctore.Typename(Ident)
  ctore.Var(Ident) 

  list.Modifiers Ident
  Annotation = ctore.Marker(Ident) 
  list.Annotations Annotation  
  ctor.Decl Ident, rec.Expr, optional.InitValue(rec.Expr)
  list.ArgDecls Decl
  list.Implements Ident
  Expr = Str | Int | Flt | Ident  | Decl                                   |  
         ctor.BinaryExpr(BinOp, rec.Expr, rec.Expr)                        |
         ctor.PrefixUnary(PrefixUnOp, rec.Expr)                            |
         ctor.SuffixUnary(rec.Expr, SuffixUnOp)                            |
         ctore.Cast(Ident, rec.Expr)                                       |
         ctore.Index(rec.Expr, rec.Expr)                                   |
         ctore.Call(rec.Expr, list.ArgList(rec.Expr))                      |
         ctore.Ternary(rec.Expr, rec.Expr, rec.Expr)                       |
         list.Statements(rec.Expr)                                         |
         ctore.FuncDecl(Annotations, Modifiers, Ident, Ident, ArgDecls, rec.Block)|
         ctore.ClassDecl(Annotations, Modifiers, Ident, Ident, Implements,rec.Block) |
         ctore.Package(Str)                                                |
         ctore.Import(Str)                                                 |
         ctore.Block(Statements)                                           |
         ctore.Paren(rec.Expr)                                             |
         ctore.Java7Lam(Ident, FuncDecl)                                   |
         ctore.If(rec.Expr, Block, optional.Block_(Block))                 |
         ctore.For(rec.Expr, rec.Expr, rec.Expr, Block)                    |
         ctore.While(rec.Expr, Block)

  
  def_out Expr  do  value.output                                                            end
  def_out Str, Int, Flt do value.inspect                                                    end
  def_out BinOp, Ident, SuffixUnOp, PrefixUnOp do value.to_s                                end
  def_out BinaryExpr do  |a, b, c| "#{b.output}#{a.output}#{c.output}"                      end
  def_out PrefixUnary do |a, b|    "#{a.output}#{b.output}"                                 end
  def_out Cast        do |a, b|    "(#{a.output})#{b.output}"                               end
  def_out SuffixUnary do |a, b|    "#{a.output}#{b.output}"                                 end
  def_out Paren      do  |expr|    "(#{expr.output})"                                       end
  def_out Index    do    |a, b|    "#{a.output}[#{b.output}]"                               end
  def_out Call     do    |a, b|    "#{a.output}(#{b.output})"                               end
  def_out Ternary do     |a, b, c| "(#{a.output}) ? (#{b.output}) : (#{c.output})"          end
  def_out ArgList  do    |list|    list.map(&:output).join(",")                             end
  def_out Statements do  |list|    list.map(&:output).join(";\n") + ";\n"                   end
  class InitValue
    def output
      unless Angen::RootClass::N === value
         " = #{value.output}"
      else
         ""
      end
    end   
  end
  def_out Decl do |type, name, init| "#{type.output} #{name.output}#{init.output}"  end
  def_out FuncDecl do |an, mo, ret, name, args, body|
        "#{an.output}\n#{mo.output} #{ret.output} #{name.output}(#{args.output})#{body.output}"
  end
  def_out ClassDecl do |an, mo, name, ext, impl, body|
        "#{an.output}\n#{mo.output} class #{name.output} extends #{ext.output}#{impl.output}#{body.output}"
  end
  def_out Annotations do |list|   list.map(&:output).join("\n") end
  def_out Modifiers   do |list|   list.map(&:output).join(" ") end
  def_out ArgDecls    do |list|   list.map(&:output).join(",") end
  def_out Marker      do |val|    "@#{val.value}" end
  def_out Implements  do |list| list.empty? ? "" : " implements " + list.map(&:output).join(",")  end
  def_out Package     do |val| "package #{val.value}" end
  def_out Import      do |val| "import #{val.value}" end
  def_out Block       do |val| "{\n#{Indent.call{val.output}}\n}" end
  
#-----------------------------------RUNNER------------------------------------------------
  
  class Expr
    
    def self.define_binop(*as)
     as.each{|a|
      define_method a do |rhs|
        effect rhs do |s, rhs|
          Expr[BinaryExpr[a, s, rhs]]
        end
      end
     }
    end
    
    def self.define_prefixop(opt = {})
     opt.each{|k, v|
      define_method v do
        effect do |s|
          Expr[PrefixUnary[k, s]]
        end
      end
     }
    end
    
     def self.define_suffixop(opt = {})
     opt.each{|k, v|
      define_method v do
        effect do |s|
          Expr[SuffixUnary[s, k]]
        end
      end
     }
    end
    
    def cast(type)
      effect do |s|
        Expr[Cast.unchecked(type, s)]
      end
    end
    def paren
      effect{|s| Paren.unchecked(s) }
    end
    
    def effect(*a)
      Unbind[yield(*[self, *a].map{|x| Extract[x]})]
    end
    
    def statement_append_(rhs)
      if Statements === value 
         u = value.clone
         u.list << rhs
         Expr[Statements[u]]
      else
         Expr[Statements[[self]]].statement_append_(rhs)
      end
    end
    
    def to_statement_
      self.value.match(Statements){|s| return Expr[Statements[s]] }
      return Expr[Statements[[self]]]
    end
        
    define_binop '+', '-', '*', '/', '==', '>=' , '=', '<=', '!=', '<', '>', '%', '^', '&', '&&', '|', '||', '>>', '<<'
    define_prefixop '++' => 'inc_p', '--' => 'dec_p'
    define_suffixop '++' => 'inc_s', '--' => 'dec_s'
    @varid = 0
    def self.var(type, value = Angen::RootClass::N[], id = :"__var$#{@varid+=1}")
      x = Expr[id]
      x.effect(type, value){|s, t, v| Expr[Decl[t,s,v]]}        
      x
    end
    
    
    def field(a)
      effect a do |s, a| Expr[BinaryExpr[".", s, a]] end  
    end
    
    def invoke(a, *args)
      effect a, *args do |s, a, *args| Expr[Call.unchecked(Expr[BinaryExpr[".", s, a]], args) ] end
    end
    
    def index(a)
      effect a do |s, a| Expr[Index[s, a]] end
    end
    
    attr_accessor :point, :index
  
    def method_missing(sym, *args)
      r = sym.to_s
      if r["="]
        self.field(sym).send("=", args[0])
      else
        invoke(sym, *args)
      end
    end
    
    def self.static(*a)
      Expr[ a.join(".").to_sym ]
    end
    
    Fn = Struct.new(:annotations, :modifiers, :ret, :name, :args)
    class Fn
      def mark(*a)
        a.each{|a|
          (self.annotations ||= []).push Marker.unchecked(a.to_sym)
        }
        self
      end
      def as(*a)
        a.each{|a|
          (self.modifiers ||= []).push a.to_sym
        }
        self
      end
      def returns(ret)
        self.ret = ret.to_sym
        self
      end
      def arg(a, b, c = Angen::RootClass::N[])
        (self.args ||= []) << Decl[a, b, c]
        self
      end
      def named(a)
        self.name = a
        self
      end  
      def create(&a)
        Expr.fn(self, &a)
      end
    end
    
    Klass = Struct.new(:annotations, :modifiers, :name, :ext, :imp)
    class Klass
      def mark(*a)
        a.each{|a|
          (self.annotations ||= []).push Marker.unchecked(a.to_sym)
        }
        self
      end
      def as(*a)
        a.each{|a|
          (self.modifiers ||= []).push a.to_sym
        }
        self
      end
      def extends(e)
        self.ext = e
        self
      end
      def implements(*a)
        (self.imp ||= []).concat a
        self
      end
      def named(a)
        self.name = a
        self
      end  
      def create(&a)
        Expr.klass(self, &a)
      end
    end
    
    def self.blk(&bl)
      r = Java.tree(&bl).result
      Expr[Block.unchecked(r.to_statement_.value)]
    end
    
    def self.fn(fn, &bl)
      Unbind[Expr[FuncDecl.unchecked(fn.annotations || [], fn.modifiers || [], fn.ret || :void, fn.name, fn.args || [], blk(&bl).value)]]
    end
    
    def self.klass(kl, &bl)
      Unbind[Expr[ClassDecl.unchecked(kl.annotations || [], kl.modifiers || [], kl.name, kl.ext || :Object, kl.imp ||[], blk(&bl).value)]]
    end
    
  end
  
  def self.name_alias(sym)
    return sym.to_s[1..-1].to_sym if sym.to_s[0] == "_"
    sym
  end
  def self.tree(&b)
    pushEnv Rewriter.new
    class_exec *b.parameters.map{|x| Expr[name_alias(x.last)]}, &b
    popEnv
  end
  
  def self.run(&b)
    r = tree(&b).result
    r.output
  end
  
  def self.package(a)
    Unbind[Package.unchecked a.to_s]
  end
  
  def self.import(a)
    Unbind[Import.unchecked a.to_s]
  end
   
  N = Angen::RootClass::N[]
  
  def self.activity(name, &b)
    Java::Expr::Klass.new.named(name.capitalize.to_sym).as(:public).extends(:Activity).create(&b)
  end
             
  def self.onCreate(types = [:"android.os.Bundle"], &b)
    fn = Java::Expr::Fn.new.named(:onCreate).as(:public).returns(:void).mark(:Override)
    b.parameters.select{|x| x.last.to_s !~ /^_/}.each_with_index{|x, i|
      fn.arg types[i], x.last
    }
    fn.create(&b)
  end
  
  class NS
    def method_missing(*a) 
      Expr.static(*a)
    end
  end
  def self.ns(*a)
    if a == []
      NS.new
    else 
      Expr.static *a
    end
  end
  
  def self.import_android(*a)
    a.each{|a|
      import "android.#{a}.*"
    }
  end
  
  def self.write(pkg, a, &b)
    IO.write a, run{
        package pkg
        class_exec &b
    }
  end
  
end


