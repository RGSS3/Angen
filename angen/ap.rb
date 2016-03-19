module Angen
  module MonadicEnv
    extend Angen
    module Identity
      def self.bind(a)
        yield a
      end
      def self.unbind(a)
        a
      end
      def self.extract(a)
        a
      end
    end
    
    Single  = I Object
    Just    = T [Single]
    Nothing = T []  
    Maybe   = Just | Nothing  
    class Maybe
      def self.bind(a, &b)
        a.match(Just){|x|
          return b.call(x)
        }.match(Nothing){
          return Nothing[]
        }
      end
      def self.unbind(a)
        Just[a]
      end
    end
    
    SingleFunc = I Proc
    FuncArrow  = T [SingleFunc]
    class FuncArrow
      def self.bind(a, &b)
        a.match(FuncArrow){|f|
          FuncArrow[lambda{|x|
            f.value[a[x]][x]
          }]
        }
      end
      def self.unbind(a)
        FuncArrow[lambda{|x|
          lambda{|y|
            a[y]
          }
        }]
      end
      def self.extract(a)
        a.match(self){|f|
         return f.value
        }
      end
    end
    
    List = L Single
    class List
      def self.bind(a, &b)
         a.match(List){|*l|
          return List[l.flat_map{|x| 
             b[x]
           }]
        }
      end
      def self.unbind(a)
        List[a]
      end
    end
    
    def ListT(t)
      list = L I t
      list.class_eval do 
        def self.bind(a, &b)
          a.match(self){|*l|
          return self[l.flat_map{|x| 
             b[x].list
           }]
          }
        end
        def self.unbind(a)
          self[a]
        end
        def self.extract(a)
          a.match(self){|*l| return l}
        end
     end
     list
    end
    
    def stack
      @stack ||= []
    end
    
    def pushEnv(a)
      stack.push(a)
    end
    
    def popEnv
      stack.pop
    end
    
    def top
      stack.last
    end
    alias env top
    
    def bind(a, &b)
      top.bind(a, &b)
    end
    
    def unbind(a)
      top.unbind(a)
    end
   
  end
end