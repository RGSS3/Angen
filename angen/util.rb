module Angen
  module Util
    extend self
    
    class MetaObject
      def initialize(obj)
        @obj = obj
      end
      
      class Methods
        def initialize(obj)
          @obj = obj
        end
        def method_missing(sym, *args)
          @obj.method(sym)
        end
        def [](sym)
          @obj.method(sym)
        end
      end
      
      def M
        @m ||= Methods.new(@obj)
      end
    end
    
    def _(obj)
      MetaObject.new(obj)
    end
    
    def build_array
      [].tap{|ret|yield ret.method(:push)}
    end
    
    def build_hash
      {}.tap{|ret|yield ret.method(:[]=)}
    end
    
    def compose(f, g)
      lambda{|*a|
         f.call(g.call(*a))
      }
    end
    
    class ComposeObject
      def initialize(obj, f)
        @obj = obj
        @f   = f
      end
      def method_missing(sym, *args, &b)
        @f.call @obj.send(sym, *args, &b)
      end
      attr_accessor :f
    end
    
    def composeObj(obj, f)
      ComposeObject.new(obj, f)
    end
    
    def reduce_with(op, b = nil, &f)
      a = []
      op = op.to_proc 
      b ||= lambda{|u|
          if a == []
            a = [u]
          else
            a = [op.call(a[0], u)]
          end
      }
      f.call(b)
      a[0]
    end
    
    def reduce_with_object(obj, op, b = nil)
       reduce_with(op, b) do |f|
         yield composeObj(obj, f)
       end
    end
    
    def def_out(*klasses, &b)
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
          instance_exec value, &b
        end
       elsif klass < Angen::RootClass::L
        klass.send :define_method, :output do
          instance_exec list, &b
        end
       end
      }
    end
 
   
    
    
  end
end