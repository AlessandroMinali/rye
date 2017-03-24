require 'rack'
require 'tilt'

# Custom error class
# Tells user that they are trying to use PARTIAL
# but it cannot be found within the /views folder
class MissingPartialTemplate < StandardError
  def initialize(partial, msg="Cannot find partial ")
    super(msg += partial.to_s)
  end
end

# A striped down version of RUM called RYE :)
class Rye
  attr_reader :env, :req, :res

  def initialize(&blk)
    @blk = blk
  end

  def call(env)
    dup._call(env)
  end

  # Compared to Rum I have removed the catch / throw blocks
  # I don't need the clutter of the functionality of nesting Rye apps
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
    res.write yield(*arg.map do |a| # directly write result of block to Rack::Response
      a == true ||
      (a != false && (a.is_a?(String) ? path(a).call : a.call)) || # check if 'a' is a string, allows sinatra like routing
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

  # Updated
  # Instead of always serving a block with default I make it
  # Bring me back to my root page. Prevents there from being
  # an infinite amount of valid urls that my app with respond
  # 200 to.
  def default
    lambda { res.redirect('/', 301) }
  end

  # Helper Method
  # Check if we are at the root of the app
  def root?
    env["PATH_INFO"] == '/'
  end

  # Helper method
  # Used in the layout to not render bottom nav
  def about?
    env["SCRIPT_NAME"] == '/about'
  end

  # Helper Method
  # Similiar to what we did in lesson 3.
  # Now with error handling!
  def find_partial(content)
    return content if content.is_a? String
    begin
      File.open(Dir["views/#{content}\.*"][0]).read
    rescue
      raise MissingPartialTemplate.new(content)
    end
  end


  {'haml': Tilt::HamlTemplate, 'markdown': Tilt::RDiscountTemplate}.each do |k,v| # I only use haml and markdown
    define_method k do |text, *args, &blk|
      args = [{}] if args.empty? # always make sure 'args' is initialized, to save on complicated checking elsewhere
      layout = args[0].fetch(:layout, :layout) # if no layout specified, default to 'layout' file
      if layout
        args[0].merge!(layout: nil) # once a layout has been chosen stop looking
        # layout is always render in haml and we pass
        # it the inner child partial that it will yield
        func = __method__
        haml(layout.to_sym, *args) { send(func, text, *args) }
      else
        template = v.new(*args) do
          find_partial text
        end
        locals = args[0][:locals]
        template.render(self, locals) { blk.call } # render view and any nested components passed to it (ie. used by layout)
      end
    end
  end
end
