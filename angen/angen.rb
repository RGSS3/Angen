module Angen
  Options = {:msg => '', :opt => ''}
  class RootClass
     def self.[](*a)
        new(*a)
     end
     if Options[:opt]
       def raise(*)
         super()
       end
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
       (Angen.U [self]) | rhs  
     end
     # ultrin
     class N < self
       def initialize(*rhs, &b)
         if !(rhs.size == 0 && !block_given? || rhs.size == 1 && rhs[0].class == N && !block_given?)
           raise (Options[:msg] || "Null type has value")
         end
       end
       def self.hash
        [:N].hash
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
       def realtype
         self.class
       end 
       
     end
     
     class T < self
       class << self
         attr_accessor :typelist, :namelist
       end
     end
     
     
     class A < self
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
    t = lambda{|*a| T *a}
    Class.new RootClass::T do
      def self.hash
        [:T, *typelist].hash
      end
      def self.eql?(rhs)
        (rhs <= RootClass::T)  && rhs.typelist.zip(self.typelist).all?{|(a, b)|a.eql?(b)} 
      end
      self.typelist = typelist
      self.namelist = namelist
      if Options[:opt]
        def self.to_s; ''; end
        def to_s; ''; end
      else
        def self.to_s
          super['#'] ? 
            "(#{typelist.map{|x| x.to_s}.join(",")})" : 
            super
        end
        define_method(:to_s) do
          "#{self.class}[#{namelist.map{|x| send(x)}.join(",")}]"
        end
      end
      
      define_method(:to_a) do
        [self.class] + namelist.map{|x| send(x).to_a}
      end
      attr_reader *namelist
      typelist.zip(namelist).each{|v|
        type, name = v
        define_method(:"#{name}=") do |rhs|
          raise (Options[:msg] || TypeError.new("#{name} #{rhs} is not a #{type} in #{self}")) if !(type === rhs) 
          instance_variable_set(:"@#{name}", type[rhs])
        end
      }
      define_method(:initialize) do |*rhs|
        if rhs.length == 1 && rhs[0].class == self.class
         namelist.each{|x| instance_variable_set(:"@#{x}", rhs[0].send(x))} 
         return
       end
        raise (Options[:msg] || ArgumentError.new("Can't implicit making struct when explicit is set, #{self.class}")) if explicit 
        raise (Options[:msg] || ArgumentError.new("Wrong number of Arguments #{self.class.to_s} #{rhs.length} #{typelist.length}")) if rhs.length != typelist.length
        rhs.each_with_index{|x, i|
          raise (Options[:msg] || TypeError.new( "#{namelist[i]} #{rhs} is not a #{typelist[i]} in #{self}"))  if !(typelist[i] === x)
        }
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
      define_method(:all) do
        namelist.map{|i| send(i) }
      end
      
      
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[*typelist.map{|x| x.gen(&b)}]
      end
      
      
      define_method(:realtype) do 
        t.call(namelist.map{|x| send(x)}.map(&:realtype))
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
  
   def A(typelist, namelist = nil, explicit = false)
    namelist ||= (0...typelist.size).map{|i| "_#{i}"}
    t = lambda{|*a| T *a}
    Class.new RootClass::T do
      def self.hash
        [:A, *typelist].hash
      end
      def self.eql?(rhs)
        (rhs <= RootClass::T)  && rhs.typelist.zip(self.typelist).all?{|(a, b)|a.eql?(b)} 
      end
      self.typelist = typelist
      self.namelist = namelist
       if Options[:opt]
        def self.to_s; ''; end
        def to_s; ''; end
      else
        def self.to_s
            super['#'] ? 
            "(@(#{typelist.map{|x| x.to_s}.join(",")})" : 
            super
        end
        define_method(:to_s) do
            "#{self.class}[#{namelist.map{|x| send(x)}.join(",")}]"
        end
      end
      define_method(:to_a) do
        [self.class] + namelist.map{|x| send(x).to_a}
      end
      attr_reader *namelist
      typelist.zip(namelist).each{|v|
        type, name = v
        define_method(:"#{name}=") do |rhs|
          raise (Options[:msg] || TypeError.new("#{name} #{rhs} is not a #{type} in #{self}")) if !(type === rhs)
          instance_variable_set(:"@#{name}", type[rhs])
        end
      }
      define_method(:initialize) do |rhs|
        if rhs.class == self.class
         namelist.each{|x|
           self.send("#{x}=", rhs.send(x))
         } 
         return
       end
        raise (Options[:msg] || ArgumentError.new("Wrong number of Arguments #{self.class.to_s} #{rhs.length} #{typelist.length}")) if (rhs.length != typelist.length)
        raise (Options[:msg] || ArgumentError.new("Can't implicit making struct when explicit is set, #{self.class}")) if explicit 
        rhs.each_with_index{|x, i|
          raise (Options[:msg] || TypeError.new("#{namelist[i]} #{rhs} is not a #{typelist[i]} in #{self}"))  if !(typelist[i] === x)
        }
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
      
      define_method(:all) do
        namelist.map{|i| send(i) }
      end
      
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[*typelist.map{|x| x.gen(&b)}]
      end
      
      
      define_method(:realtype) do 
        t.call(namelist.map{|x| send(x)}.map(&:realtype))
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
    l = lambda{|a| L a}
    Class.new RootClass::L do
      self.type = type
       def self.hash
        [:L, type].hash
      end
      attr_accessor :list
      attr_accessor :type
       if Options[:opt]
        def self.to_s; ''; end
        def to_s; ''; end
      else
        def to_s
            "#{self.class}[#{self.list.join(",")}]" 
        end
        def self.to_s
            super['#'] ? 
            "[#{self.type.to_s}]" :  
            super
        end
      end
      def to_a
        [self.class] + self.list.map{|x| x.to_a}
      end
      define_method(:initialize) do |rhs|
        if rhs.class == self.class
          self.list = rhs.list[0..-1]
          return
        end
        raise (Options[:msg] || TypeError.new("Not an array for #{rhs.inspect} in #{self.class}")) if !(Array === rhs)
        rhs.each_with_index{|x, i|
          raise (Options[:msg] || TypeError.new("#{type} mismatched #{x.class} #{Array === x ? x : ''} for #{self.class}")) if !(type === x)  
        }
        self.list = [] 
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
          b.call(list)
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
      define_method(:realtype) do 
        l.call list.map(&:realtype).uniq.inject(:|)
      end
      def self.eql?(rhs)
        (rhs <= RootClass::L) && self.type.eql?(rhs.type)
      end
    end
  end
  
  def I(type)
    ii = lambda{|a| I type}
    Class.new RootClass::I do
      self.type = type
      def self.hash
        [:I, type].hash
      end
      attr_accessor :type, :value
      def self.eql?(rhs)
        (rhs <= RootClass::I)  && self.type.eql?(rhs.type)
      end
       if Options[:opt]
        def self.to_s; ''; end
        def to_s; ''; end
      else
        def to_s
            "#{self.class.to_s}[#{@value}]"
        end
      
        def self.to_s
            super['#'] ? 
            "#{self.type.to_s}" : 
            super
        end
      end
      def to_a
        [@value]
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
        raise (Options[:msg] || TypeError.new("#{rhs.class} is not #{type}"))
      end
      (class << self; self; end).send(:define_method, :parse) do |str, &b|
        b[str, self].map{|x| [self[x[0]], x[1]]}
      end
      (class << self; self; end).send(:define_method,:gen) do |&b|
        self[b.call(self)]
      end
      define_method(:realtype) do 
        self.class
      end
    end
  end
  def R(outer, name)
    Class.new RootClass::R do
      self.outer = outer
      self.name  = name
      def self.to_s
        "R #{outer.to_s} #{name}"
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
       if Options[:opt]
        def self.to_s; ''; end
        def to_s; ''; end
      else
        def self.to_s
            super['#'] ? 
            "#{self.types.map{|x| x.to_s}.join(" | ")}" : 
            super
        end
        def to_s
          "#{self.class.to_s}[#{@value}]"
        end
      end
      define_method(:match) do |rhs, &b|
        @value.match(rhs, &b)
        self
      end
      
      attr_accessor :type, :value
      define_method(:rewrite) do |&b|
        self.class[@value.rewrite(&b)]
      end
      (class << self; self; end).send :define_method, :deduce do |rhs|
       types.each{|t|
          begin
            t === rhs
            return t
          rescue
            
          end
        }
      end
      const_set :CACHE, {}
      define_method(:initialize) do |rhs|
        if rhs.class == self.class
          @type = rhs.type
          @value = rhs.value
          return
        end        
        types.each{|t|
          if t == rhs.class
            @type  = t
            @value = rhs
            return
          end
        }
        types.each{|t|
          if t <= RootClass::I && t === rhs
            @type = t
            @value = t.new(rhs)
            return 
          end
        }
        types.each{|t|
          begin
            @type  = t
            @value = t.new(rhs)
            return
          rescue

          end
        }
        raise (Options[:msg] || TypeError.new("No such subtype #{rhs.inspect} in #{self.class}"))  
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
      
      define_method(:realtype) do
        self.value.realtype
      end 
      def self.eql?(rhs)
        (rhs <= RootClass::U) && self.types.sort.eql?(rhs.types.sort)
      end
      def self.hash
        [:U, self.types].hash
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
    
  class CTorA
    def initialize(obj)
      @obj = obj
    end
    def method_missing(sym, *args)
      @obj.const_set(sym, Angen.A(args))
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
  def ctora(pool = self)
    CTorA.new pool
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