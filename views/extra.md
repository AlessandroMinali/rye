###Lesson 2

In the <a href="/lesson/1" target="_blank">previous tutorial</a> I introduced the micro-framework <a href="https://github.com/chneukirchen/rum" target="_blank">rum</a> and how it works as a <a href="http://rack.github.io" target="_blank">rack</a> app. In this example we will be looking at a more complex app. This will take us through more of the functionality that the framework provides us. The lessons learnt from this basic framework can be applied when looking at more complex ones such as <a href="http://www.sinatrarb.com" target="_blank">sinatra</a> and <a href="https://rubyonrails.org" target="_blank">rails</a>, which are rack apps themselves. Here is the code we will be breaking down:

    require '../lib/rum'

    use Rack::ShowStatus

    module Kernel
      def info(title, r)
        r.res['Content-Type'] = "text/plain"
        r.res.write "At #{title}\n"
        r.res.write "  SCRIPT_NAME: #{r.req.script_name}\n"
        r.res.write "  PATH_INFO: #{r.req.path_info}\n"
      end
    end

    run Rum.new {
      on path('foo') do
        info("foo", self)
        on path('bar') do
          info("foo/bar", self)
        end
      end
      on get, path('say'), segment, path('to'), segment do |_, _, what, _, whom, _|
        info("say/#{what}/to/#{whom}", self)
      end
      also
      on default do
        info("default", self)
      end
    }
This is one of the examples that come in the <a href="https://github.com/chneukirchen/rum" target="_blank">rum repo from github</a>. If you haven't already, grab the repo and run the app from the `/sample` folder with the command `rackup path.ru`.  Go to <a href="http://localhost:9292" target="_blank">http://localhost:9292</a> and see if you can guess/visit all the valid paths this app serves besides the default fallback response.
- - -
Let's get started. I'll be skimming over things I've already covered and pointing out new or interesting features I have yet to discuss, the first being:
    
    use Rack::ShowStatus
`:use` is a <a href="https://github.com/rack/rack/blob/4b33af1c80c822cbcbb69113ff1e54f9454921c1/lib/rack/builder.rb#L62-L87" target="_blank">rack method</a> that is *used* to load in <a href="http://stackoverflow.com/questions/2256569/what-is-rack-middleware" target="_blank">middleware</a>, which "catches all empty responses and replaces them with a site explaining the error." Middleware is a pretty cool part of rack that allows you to stack and rearrange rack apps on top of each other. Each middleware is a rack app that has a chance to add or change the `env`, `response` and `request` before passing it to the next app. For example rails is basically a giant tower of rack middleware! Here is a peek at what a default rails app looks like: 

	use Rack::Sendfile
	use ActionDispatch::Static
	use ActionDispatch::Executor
	use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
	use Rack::Runtime
	use Rack::MethodOverride
	use ActionDispatch::RequestId
	use Rails::Rack::Logger
	use ActionDispatch::ShowExceptions
	use ActionDispatch::DebugExceptions
	use ActionDispatch::RemoteIp
	use ActionDispatch::Reloader
	use ActionDispatch::Callbacks
	use ActiveRecord::Migration::CheckPending
	use ActiveRecord::ConnectionAdapters::ConnectionManagement
	use ActiveRecord::QueryCache
	use ActionDispatch::Cookies
	use ActionDispatch::Session::CookieStore
	use ActionDispatch::Flash
	use Rack::Head
	use Rack::ConditionalGet
	use Rack::ETag
	run Rails.application.routes
   
   Anyhow, continuing on we have this module definition: 

    module Kernel
      def info(title, r)
        r.res['Content-Type'] = "text/plain"
        r.res.write "At #{title}\n"
        r.res.write "  SCRIPT_NAME: #{r.req.script_name}\n"
        r.res.write "  PATH_INFO: #{r.req.path_info}\n"
      end
    end

Here we are taking advantage of the ruby **Kernel** module and appending a new method. The **Kernel** is special in that every ruby object can use it's methods. This `:info` will come up later as our own personal helper method.

    run Rum.new { ... }

Once again we find yourselves in familiar water. If you don't know what this does, visit the <a href="/lesson/1" target="_blank">last tutorial</a> where I explain how rack setups up our app. Let's go straight to the first `:on` block:

      on path('foo') do
        info("foo", self)
        on path('bar') do
          info("foo/bar", self)
        end
      end
 
 Let's assume a user attempts to hit our site with the url <a href="http://localhost:9292/foo" target="_blank">http://localhost:9292/foo</a>. `path('foo')` is called to be passed into `:on`:

    def path(p)
      lambda {
        if env["PATH_INFO"] =~ /\A\/(#{p})(\/|\z)/
          env["SCRIPT_NAME"] += "/#{$1}"
          env["PATH_INFO"] = $2 + $'
          $1
        end
      }
    end
  Rum setups up a [lambda](http://awaxman11.github.io/blog/2013/08/05/what-is-the-difference-between-a-block/) which is basically a block of code that can be evaluated at some other point in time when you `:call` it. This is passed into `:on` and so `*arg` becomes an array holding the lambda as it's single element. Inside `:on`, `@matched` is still false so we move forward and make a copy of some `env` variables.

    def on(*arg, &block)
      .
      .
      yield *arg.map { |a| a == true || (a != false && a.call) || return }

Here the first condition fails, so we evaluate the second one. `a` in this case is our lambda so it is not `false` and `a.call` is run:

    lambda {
      if env["PATH_INFO"] =~ /\A\/(#{p})(\/|\z)/
        env["SCRIPT_NAME"] += "/#{$1}"
        env["PATH_INFO"] = $2 + $'
        $1
      end
    }
 
 `p` was passed to the lambda earlier as `'foo'`. If a match is found`$1` and `$2` will be assigned as the first and second matching string group from the regex respectively. `$'` will be anything left over. The successful match is returned as the output of the conditional. This is mapped back to the `arg` array, passed to `yield` and the block is now evaluated:

    info("foo", self)
    on path('bar') do
      info("foo/bar", self)
    end
 
 Our previously defined `:info` method is called and appends content to the **Rack::Response** object we are using. This is accessed from the Kernel by passing in `self` which is the **Rum** object that contains the **Rack::Response**.

Before breaking out of this `:on` call we find ourselves hitting another one:
    
    on path('bar') do
      info("foo/bar", self)
    end
The same process of storing and then evaluating the `:path` lambda occurs but this time the regex fails to match. Therefore the last condition of `|a| a == true || (a != false && a.call) || return` is evaluated, avoiding yielding the block. We now return back to the outside `on path('foo') do` block.

Continuing execution we reassign the `env` variables we stored and mark `@matched` as true. We now hit another `:on` block:
    
    run Rum.new {
      .
      .
      .
      on get, path('say'), segment, path('to'), segment do |_, _, what, _, whom, _|
        info("say/#{what}/to/#{whom}", self)
      end

Each parameter passed to the `:on`  method is first evaluated and sent to `*arg`. The only methods we haven't seen yet are,  `:get`:

    def get; req.get?; end

which simply queries the **Rack::Response** object to see if the user is making a `get` HTTP request and `:segment` :

    def segment
      path("[^\\/]+")
    end
which is just a specific `:path` call, and we already know how those work. Needless to say after putting all these into the `*arg ` array the first line of `:on` kicks us out since `@matched` has been set to `true`. None of the lambdas or the nested block are evaluated.

The next line has a single call to the `:also` method:

    def also
      @matched = false
    end
This resets the state of matching so the next `:on` block we encounter will be processed completely. And he comes up right after:

    on default do
      info("default", self)
    end
I won't go into details but this final `:on` call will always match since `:also` resets the state just before it and `:default` is always `true`. This means that every response from our app will at least give us the content of one `:info` call! Neat.

Hopefully you now have a feel of how the rum router works in deciding on what to render for the user. Test your knowledge and see if you can work through what happens on each of these requests to our app:

 - <a href="http://localhost:9292/foo/bar" target="_blank">http://localhost:9292/foo/bar</a>
 - <a href="http://localhost:9292/foo/test" target="_blank">http://localhost:9292/foo/test</a>
 - <a href="http://localhost:9292/bar/foo" target="_blank">http://localhost:9292/bar/foo</a>
 - <a href="http://localhost:9292/say/hello/to/mom" target="_blank">http://localhost:9292/say/hello/to/mom</a>
 - <a href="http://localhost:9292/say/goodbye/to/my/dog/" target="_blank">http://localhost:9292/say/goodbye/to/my/dog/</a>
 - <a href="http://localhost:9292/foo/say/nothing" target="_blank">http://localhost:9292/foo/say/nothing</a>
 - <a href="http://localhost:9292/foo/bar/say/hello/to/mom/for/me" target="_blank">http://localhost:9292/foo/bar/say/hello/to/mom/for/me</a>

Now that you are confident with the rum framework try building a little personal webpage! Customize the routes you want to have and make your own custom html pages to show on each one!

######[Want to add custom pages to your rum app? Next lesson ->](/lesson/3)
- - -
Sources:  
<a href="https://github.com/chneukirchen/rum" target="_blank">https://github.com/chneukirchen/rum</a>  
<a href="http://rack.github.io" target="_blank">http://rack.github.io</a>  
<a href="https://github.com/rack/rack" target="_blank">https://github.com/rack/rack</a>  

