module Angen
  class RootClass
     def self.[](*a)
        new(*a)
     end
     def self.===(*rhs)
       return true if rhs.length == 1 && rhs[0].class == self
       begin
         new(*rhs)
         true
       rescue 
         false
       end
     end
     def self.| rhs
       Angen.U [self, rhs]  
     end
     
     # ultrin
     class N < self
       def initialize(*rhs, &b)
         if !(rhs.size == 0 && !block_given? || rhs.size == 1 && rhs[0].class == N && !block_given?)
           raise "Null type has value"
         end
       end
       define_method(:rewrite) do |&b|
         b.call(self)
       end
       def to_a
         []
       end
       define_method(:match) do |rhs, &b|
        if self.class == rhs
          b.call
        end
        self
       end
       (class << self; self; end).send(:define_method, :parse) do |str, &b|
         [[N[], str]]
       end
       (class << self; self; end).send(:define_method,:gen) do |&b|
         self[]
       end
     end
     
     class T < self
       class << self
         attr_accessor :typelist, :namelist
       end
     end
     class I < self
       class << self
         attr_accessor :type
       end
     end
     class L < self
       class << self
         attr_accessor :type
       end
     end
     class U < self
       class << self
         attr_accessor :types
       end
     end
     class R < self
       class << self
         attr_accessor :outer, :name
       end
     end
  end
  extend self
  def T(typelist, namelist = nil, explicit = false)
    namelist ||= (0...typelist.size).map{|i| "_#{i}"}
    Class.new RootClass::T do
      self.typelist = typelist
      self.namelist = namelist
      def self.to_s
        super['#'] ? 
          "T [#{typelist.map{|x| x.inspect}.join(",")}]" : 
          super
      end
      define_method(:to_s) do
          "#{self.class}[#{namelist.map{|x| send(x)}.join(",")}]"
      end
      define_method(:to_a) do
        [self.class] + namelist.map{|x| send(x).to_a}
      end
      attr_reader *namelist
      typelist.zip(namelist).each{|v|
        type, name = v
        define_method(:"#{name}=") do |rhs|
          raise TypeError.new("#{name} #{rhs} is not a #{type} in #{self}") if !(type === rhs)
          instance_variable_set(:"@#{name}", type[rhs])
        end
      }
      define_method(:initialize) do |*rhs|
        if rhs.length == 1 && rhs[0].class == self.class
         namelist.each{|x|
           self.send("#{x}=", rhs[0].send(x))
         } 
         return
       end
        raise ArgumentError.new("Can't implicit making struct when explicit is set, #{self.class}") if explicit
        raise ArgumentError.new("Wrong number of Arguments #{self.class.to_s} #{rhs.length} #{typelist.length}") if rhs.length != typelist.length
        rhs.each_with_index{|x, i|
          self.send("#{namelist[i]}=", x)
        }
      end
      (class << self; self; end).send :define_method, :unchecked do |*rhs|
        allocate.instance_eval do
          rhs.each_with_index{|x, i|
            self.send("#{namelist[i]}=", x)
          }
          self
        end
      end
      define_method(:[]) do |i|
        self.send("#{namelist[i]}")
      end
      define_method(:[]=) do |i, a|
        self.send("#{namelist[i]}=", a)
      end
      define_method(:rewrite) do |&b|
        b.call(self.class.unchecked(*namelist.map{|i|send(i).rewrite(&b) }))
      end
      
      define_method(:match) do |rhs, &b|
        if self.class == rhs
         b.call(*namelist.map{|i| send(i) })
        end
        self
      end
      
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[*typelist.map{|x| x.gen(&b)}]
      end
      
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
        r = [[[], str]]
        typelist.each{|x|
          r = r.flat_map{|lastmatch|
            obj, str = lastmatch
            u = x.parse(str, &b)
            u.map{|newmatch|
              [obj + (newmatch[0].is_a?(Array) ? newmatch[0] : [newmatch[0]]), newmatch[1]]
            }
          }
        }
        r.map{|x| [self[*x[0]], x[1] ]}
      end
    end
  end
  
  def L(type)
    Class.new RootClass::L do
      self.type = type
      attr_accessor :list
      attr_accessor :type
      def to_s
        "#{self.class}[#{self.list.join(",")}]" 
      end
      def self.to_s
        super['#'] ? 
        "L [#{self.type.inspect}]" :  
        super
      end
      def to_a
        [self.class] + self.list.map{|x| x.to_a}
      end
      define_method(:initialize) do |rhs|
        if rhs.class == self.class
          self.list = rhs.list[0..-1]
          return
        end
        self.list = []
        raise TypeError, "Not an array for #{rhs.inspect} in #{self.class}" if !(Array === rhs)
        rhs.each_with_index{|x, i|
          raise TypeError.new("#{type} #{x.class} for #{self.class}") if !(type === x)
        }
        self.type = type
        self.list = rhs.map{|x| type.new(x) }
      end
      (class << self; self; end).send :define_method, :unchecked do |*rhs|
        allocate.instance_eval do
          self.type = type
          self.list = rhs.map{|x| type.new(x) }
          self
        end
      end
      define_method(:match) do |rhs, &b|
        if self.class == rhs
          b.call(*list)
        end
        self
      end
      define_method(:rewrite) do |&b|
        b.call(self.class[self.list.map{|x| x.rewrite(&b)}])
      end
      def [](i)
        self.list[i]
      end
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
        r = [[[], str]]
        loop do
          found = true
          s = r.flat_map{|lastmatch|
            obj, str = lastmatch
            u = type.parse(str, &b)
            found = false if u == []
            u.map{|newmatch|
              [obj + (newmatch[0].is_a?(Array) ? newmatch[0] : [newmatch[0]]), newmatch[1]]
            }
          }
          break if !found
          r.concat s
        end
        r.map{|x| [self[x[0]], x[1]]}
      end
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[b.call(self)]
      end
    end
  end
  
  def I(type)
    Class.new RootClass::I do
      self.type = type
      attr_accessor :type, :value
      def to_s
        "#{self.class.to_s}[#{@value}]"
      end
      def to_a
        [@value]
      end
      def self.to_s
        super['#'] ? 
        "I [#{self.type.inspect}]" : 
        super
      end
      define_method(:match) do |rhs, &b|
        if self.type == rhs
          b.call(self.value)
        elsif self.class == rhs
          b.call(self)
        elsif rhs === self
          b.call(self)
        end
        self
      end
      define_method(:rewrite) do |&b|
        b.call(self)
      end
      define_method(:initialize) do |rhs|
       if rhs.is_a?(RootClass::I) && type === rhs.value
          self.type  = type
          self.value = rhs.value
          return
        end
        if type === rhs
          self.type  = type
          self.value = rhs
          return
        end
        raise TypeError.new("#{rhs.class} is not #{type}")
      end
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
        b[str, self].map{|x| [self[x[0]], x[1]]}
      end
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[b.call(self)]
      end
    end
  end
  def R(outer, name)
    Class.new RootClass::R do
      self.outer = outer
      self.name  = name
      def self.to_s
        "R #{outer.inspect} #{name}"
      end
      (class << self; self; end).send :define_method, :new do |*rhs|
        outer.const_get(name).new(*rhs)
      end
      (class << self; self; end).send :define_method, :[] do |*rhs|
        self.new(*rhs)
      end
      (class << self; self; end).send :define_method, :=== do |*rhs|
        outer.const_get(name).=== *rhs
      end
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
         outer.const_get(name).parse(str, &b)
      end
      (class << self; self; end).send(:define_method, :gen) do |&b|
         outer.const_get(name).gen(&b)
      end
    end
  end
  
  def U(types)
    Class.new RootClass::U do
      self.types = types
      def to_s
        "#{self.class.to_s}[#{@value}]"
      end
      def to_a
        @value.to_a
      end
      def self.to_s
        super['#'] ? 
        "U [#{self.types.map{|x| x.inspect}.join(" | ")}]" : 
        super
      end
      define_method(:match) do |rhs, &b|
        @value.match(rhs, &b)
        self
      end
     
      attr_accessor :type, :value
      define_method(:rewrite) do |&b|
        self.class[@value.rewrite(&b)]
      end
      define_method(:initialize) do |rhs|
        if rhs.class == self.class
          @type = rhs.type
          @value = rhs.value
          return
        end
        types.each{|t|
          if t === rhs
            @type  = t
            @value = t.new(rhs)
            return
          end
        }
        raise TypeError.new("No such subtype #{rhs.inspect} in #{self.class}")
      end
      (class << self; self; end).send :define_method, "|" do |rhs|
        case 
          when rhs.is_a?(Array)            then Angen.U types + rhs
          when rhs.is_a?(RootClass::U)     then Angen.U types + rhs.types
          else Angen.U types + [rhs]
        end
      end
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
        r = [[[], str]]
        s = []
        types.each{|x|
          s.concat r.flat_map{|lastmatch|
            obj, str = lastmatch
            u = x.parse(str, &b)
            u.map{|newmatch|
              [obj + (newmatch[0].is_a?(Array) ? newmatch[0] : [newmatch[0]]), newmatch[1]]
            }
          }
        }
        s.map{|x| [self[*x[0]], x[1] ]}
      end
      (class << self; self; end).send(:define_method, :gen) do |&b|
         self[types.sample.gen(&b)]
      end
       
    end
  end
  
  class CTor
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      @obj.const_set(sym, Angen.T(args))
    end
  end
  
  class CTorE
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      @obj.const_set(sym, Angen.T(args, nil, true))
    end
  end
  
  class Type
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      @obj.const_set(sym, Angen.I(*args))
    end
  end
  
  class Rec
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      Angen.R(@obj, sym)
    end
  end
  
  class List
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      @obj.const_set(sym, Angen.L(*args))
    end
  end
  
    
  class Optional
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, arg)
      @obj.const_set(sym, arg | Angen::RootClass::N)
    end
  end
  
  def ctor(pool = self)
    CTor.new pool
  end
  def ctore(pool = self)
    CTorE.new pool
  end
  def type(pool = self)
    Type.new pool
  end
  def rec(pool = self)
    Rec.new pool
  end
  def list(pool = self)
    List.new pool
  end
  def optional(pool = self)
    Optional.new pool
  end
end