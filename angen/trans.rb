require 'ripper'
module Angen
  module Translate
    def _translate(arr, &b)
      if Array === arr[0]
        return arr.map{|x| _translate(x, &b)}
      end
      u = [arr[0]] + arr[1..-1].map{|x| 
        if Array === x
          _translate(x, &b)
        else
          x
        end
      }
      b.call(u)
    end
    def translate(a, &b)
      r = Ripper.sexp(a)
      _translate(r, &b)
    end
  end
end
