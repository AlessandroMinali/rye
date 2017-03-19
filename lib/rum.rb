require 'rack'
require 'tilt'

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
    yield *arg.map { |a| a == true || (a != false && a.call) || return }
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

  def param(p, default=nil)
    lambda { req[p] || default }
  end

  def params(p, default=nil)
    req[p] || default
  end

  def default
    true
  end

  def find_partial(content)
    return content if content.is_a? String
    File.open(Dir["views/#{content}\.*"][0]).read
  end

  # Tilt.default_mapping.lazy_map.each do |ext, engines|
  #   engines.each do |e|
  #     begin
  #       engine = Object.const_get(e[0])
  #     rescue LoadError, NameError => e
  #       next
  #     end
  #     define_method ext do |text, *args|
  #       template = engine.new(*args) do
  #         find_partial text
  #       end
  #       locals = (args[0].respond_to?(:[]) ? args[0][:locals] : nil) || {}
  #       res.write template.render(self, locals)
  #     end
  #     break
  #   end
  # end
  def markdown(text, *args)
    template = Tilt::RDiscountTemplate.new(*args) do
      find_partial text
    end
    locals = (args[0].respond_to?(:[]) ? args[0][:locals] : nil) || {}
    res.write template.render(self, locals)
  end
end
