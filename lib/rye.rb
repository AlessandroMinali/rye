require 'rack'
require 'tilt'
require 'pry'

class MissingPartialTemplate < StandardError
  def initialize(partial, msg="Cannot find partial ")
    super(msg += partial.to_s)
  end
end

class Rum
  attr_reader :env, :req, :res

  def initialize(&blk)
    @blk = blk
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    @env = env
    @req = Rack::Request.new(env)
    @res = Rack::Response.new
    @matched = false
    instance_eval(&@blk)
    @res.status = 404  unless @matched || !@res.empty?
    @res.finish
  end

  def on(*arg, &block)
    return if @matched
    s, p = env["SCRIPT_NAME"], env["PATH_INFO"]
    res.write yield(*arg.map do |a|
      a == true ||
      (a != false && (a.is_a?(String) ? path(a).call : a.call)) ||
      return
    end)
    env["SCRIPT_NAME"], env["PATH_INFO"] = s, p
    @matched = true
  end

  def path(p)
    lambda {
      if env["PATH_INFO"] =~ /\A\/(#{p})(\/|\z)/   #/
        env["SCRIPT_NAME"] += "/#{$1}"
        env["PATH_INFO"] = $2 + $'
        $1
      end
    }
  end

  def number
    path("\\d+")
  end

  def default
    lambda { res.redirect('/', 301) }
  end

  def root?
    env["PATH_INFO"] == '/'
  end

  def about?
    env["SCRIPT_NAME"] == '/about'
  end

  def find_partial(content)
    return content if content.is_a? String
    begin
      File.open(Dir["views/#{content}\.*"][0]).read
    rescue
      raise MissingPartialTemplate.new(content)
    end
  end

  {'haml': Tilt::HamlTemplate, 'markdown': Tilt::RDiscountTemplate}.each do |k,v|
    define_method k do |text, *args, &blk|
      args = [{}] if args.empty?
      layout = args[0].fetch(:layout, :layout)
      if layout
        args[0].merge!(layout: nil)
        haml(layout.to_sym, *args) { send(__method__, text, *args) }
      else
        template = v.new(*args) do
          find_partial text
        end
        locals = args[0][:locals]
        template.render(self, locals) { blk.call }
      end
    end
  end
end
