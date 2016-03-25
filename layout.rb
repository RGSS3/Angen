require 'angen'
module Layout
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
           
 #--------------LANGUAGE-------------------------------------------------------------
    type.Str String
    type.Tag Symbol
    type.AttrName Symbol
    type.Attr Hash
    list.Childnode rec.XMLNode
    type.AttrValue String
    XMLAttr = AttrName | AttrValue
    XMLNode = T [Tag, Attr, Childnode], [:tagname, :attrs, :node]
    class XMLNode
      def unbind(node)
         self.node.list << node unless self.node.list.index{|x| x.hash == node.hash}
         node
      end
      def extract(node)
         self.node.list.delete_if{|x| x.hash == node.hash}
         node
      end
    end
    
    def_out Str do |s| s.inspect end
    def_out Tag do |s| s.to_s    end
    def_out Attr do |s|
        s.empty? ? "" : " " + 
        s.map{|k, v|
        "#{XMLAttr[k].output} = #{XMLAttr[v].output}"
        }.join(" ")
    end
    def_out XMLAttr do |s| value.output end
    def_out AttrName do |s| s.to_s end
    def_out AttrValue do |s| s.inspect end
    def_out XMLNode do |tag, attr, children|
       if children.list.empty?
         "<#{tag.output}#{attr.output}/>"
       else
        "<#{tag.output}#{attr.output}>\n#{Indent.call{children.output}}\n</#{tag.output}>"
       end
    end
    def_out Childnode do |list|
      list.map(&:output).join("\n")
    end
    
    
    
    def self.define_verb(*a)
     a.each{|tagname|
       (class << self; self; end).send :define_method, tagname do |opt = {}, &b|
           pushEnv XMLNode[tagname, opt, []]
           b.call if b
           r = popEnv
           Unbind[r]
           r
       end
     }
    end
    
    def self.define_android_verb(*a)
     a.each{|tagname|
       (class << self; self; end).send :define_method, tagname do |opt = {}, &b|
           pushEnv XMLNode[tagname, opt.map{|k, v| ["android:#{k}".to_sym, v]}.to_h, []]
           b.call if b
           r = popEnv
           Unbind[r]
           r
       end
     }
    end
    
    def self.topnode(tagname, opt = {}, &b)
      u = send(tagname, opt, &b)
      u[1].value = {:"xmlns:android"=>"http://schemas.android.com/apk/res/android",
                     :"xmlns:tools"=>"http://schemas.android.com/tools",
                     :"android:orientation"=>"vertical",
                     :"android:layout_width"=>"match_parent",
                     :"android:layout_height"=>"match_parent",
                     :"android:background"=>"#FFFFFF",
                     :"tools:context"=>".MainActivity"}.merge(u[1].value)
      u
    end
    define_android_verb :LinearLayout
    define_android_verb :Button
    define_android_verb :EditText
    def self.horizontal(opt = {})
      LinearLayout({layout_width: "match_parent", layout_height: "wrap_content", orientation: "horizontal"}.merge(opt))do 
        yield
      end
    end
    
    def self.vertical(opt = {})
      LinearLayout({layout_width: "wrap_content", layout_height: "match_parent", orientation: "vertical"}.merge(opt))do 
        yield
      end
    end
    
    @id = 0
    def self.define_hcontrol(name, name2)
     (class << self; self; end).send :define_method, name do |text = "", len = 1, width = "match_parent", height = "wrap_content", name = "__btn#{@id+=1}"|
       send name2, layout_width: width.to_s, layout_height: height.to_s, text: text.to_s, layout_weight: len.to_s, id: "@+id/#{name}"
       name
     end
    end 
    
    define_hcontrol(:hbutton, :Button)
    define_hcontrol(:htext, :EditText)
    
    def self.write(a, &b)
      IO.write a, run{
          class_exec &b
      }
    end
    
    def self.run(&b)
      class_exec(&b).output
    end
end

