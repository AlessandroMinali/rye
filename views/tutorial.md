### Lesson 1

I'll be going step by step through how the ruby micro-framework <a href="https://github.com/chneukirchen/rum" target="_blank">rum</a> works using the simplest example I can think of:

    require '../lib/rum'
    run Rum.new {
      on default do
        puts 'Hello, World!'
      end
    }

Grab the <a href="https://github.com/chneukirchen/rum" target="_blank">rum repo from github</a>. Save the above code in the  `/sample` folder of the repo as `simple.ru`, then you should be able to run it with `rackup simple.ru` in your terminal. Go to <a href="http://localhost:9292" target="_blank">http://localhost:9292</a> in your browser to see what it does.

The following lessons contain alot of condensed knowledge in them. Don't be afraid to re read them over and over until you get a full grasp of what's going. Feel free to <a href="/about" target="_blank">reach out to me</a> if you have something you can't figure out!
- - -
Let's start and see how this micro-framework works!

    require '../lib/rum'

We ask ruby to load the rum library from our machine. This goes to rum.rb and loads the <a href="http://rack.github.io" target="_blank">rack</a> library with `require 'rack'` and setups up our two classes **Rack::Response** and **Rum**.

    run Rum.new {...}
Here we pass our app to rack. In the end all rack wants from us is i. an **object** that responds to `:call` with one parameter and ii. returns an array with three elements:
  

 1. HTTP response code
 2. hash of headers
 3. the response body which must respond to `:each`

If we really want to show off we could implement this simple rum app as a single line: 
`run Proc.new { |env| [200, {'Content-Type' => 'text/html'}, ['Hello, World!']] }`
but the point of rum is to allow us to respond to many different situations vs. just serving a single response every time.

`Rum.new` executes the `:initialize` method:

    def initialize(&blk)
      @blk = blk
    end
This expects a `block` to be given and assigns it to a local variable so that essentially: 

    @blk = Proc.new do
             on default do
               puts 'Hello, World!'
             end
           end
 
 At this point our app is setup and now awaits some activity from someone trying to reach our server.

Now here is the cool part, when the server gets a request, rack tries to handle it and our proc is lazily evaluated to generate the response! Rum finally gets to jump in and do some work.

As I mentioned above rack's entry point into app is through the `:call` method. Here's rum's:

    def call(env)
      dup._call(env)
    end
Rum makes a <a href="http://ruby-doc.org/core-2.4.0/Object.html#method-i-dup" target="_blank">duplicate</a> of itself to avoid carrying over instance variables and the like between requests. With a fresh and clean copy of the **Rum** object we continue processing the call:

    def _call(env)
      @env = env
      @req = Rack::Request.new(env)
      @res = Rack::Response.new
      @matched = false
      catch(:rum_run_next_app) {
        instance_eval(&@blk)
        @res.status = 404  unless @matched || !@res.empty?
        return @res.finish
      }.call(env)
    end

`env` is holding all the <a href="http://www.rubydoc.info/github/rack/rack/master/file/SPEC#The_Environment" target="_blank">environment variables</a> that rack provides us, we take a copy as it may be modified elsewhere. We use `Rack::Request` and `Rack::Response` as convenient interfaces to work with rack. `@matched` will become a flag to track if we have found an appropriate route for the incoming request.  `catch(:rum_run_next_app)` is an error handling block that rum provides for one of it's helper methods `:run`, we'll talk about it in a later tutorial. For now we are interested in what happens in the block:
   
    instance_eval(&@blk)
    @res.status = 404  unless @matched || !@res.empty?
    return @res.finish
The proc we saved upon initialization is now ready to be processed so we run it with `:instance_eval`. This makes it run in the local context of the **Rum** object. And the magic begins...Just incase you forgot we will be evaluating this code finally:

    # inside simple.ru  
    on default do
      puts 'Hello, World!'
    end
First up is:

    def on(*arg, &block)
      return  if @matched
      s, p = env["SCRIPT_NAME"], env["PATH_INFO"]
      yield *arg.map { |a| a == true || (a != false && a.call) || return }
      env["SCRIPT_NAME"], env["PATH_INFO"] = s, p
      @matched = true
    end
The method takes two parameters, the last being a block. The *first* parameter actually grabs all values passed in and puts them into a single array which we can reference with `arg`. Entering the method, the first line checks our `@matched` variable but that is still false.  Next we make copies of some env variables as again they will be altered. 

Hitting the `yield *arg.map { |a| a == true || (a != false && a.call) || return }` we now traverse into the block that we passed in. `*arg` in this case it was `default`:
    
    def default
      true
    end
so we end up with `[true].map { ... }`. Luckily `|a| a == true || (a != false && a.call) || return` evaluates right away since `a == true`, and that gets <a href="https://ruby-doc.org/core-2.2.0/Array.html#method-i-map" target="_blank">mapped</a> back to `*arg`.

Therefore we have `yield true` which passes `true` to:
  
    puts 'Hello, World!'
The block executes completely ignoring our passed in parameter since we don't reference it anywhere.  Rum provides an overwritten version of the `:puts` method:

    def puts(*args)
      args.each { |s|
        res.write s
        res.write "\n"
      }
    end
This takes the string and writes it to our response object!

Now we exit from the yield block and continue executing `:on`. In next line we reassign the env variables we stored earlier and, since we found our route, we set `@matched` to equal true to prevent further parsing. Then we exit from the `:instance_eval(&@blk)` line! Phew!

The only thing left is to wrap up the response so rack can send it to our visitor. Just as a refresher we are back here:

    def _call(env)
      .
      .
      .
      catch(:rum_run_next_app) {
        instance_eval(&@blk)
        @res.status = 404  unless @matched || !@res.empty?
        return @res.finish
      }.call(env)
    end
  
 The next line is skipped as the conditional evaluates to true. If you find `:unless` confusing you can think of that line like this: 

     if !@matched || @res.empty?
       @res.status = 404
     end
Since we matched, we'll keep the default value of the status code which is `200`. And lastly we signal to rack that we are done and send it the 3 element array it is expecting (conveniently already assemble since we used **Rack::Response**). The `return` exits `:_call` and then the original `:call` finishes as well completing rack's execution of our app. It takes the value returned and generates the webpage.

The user now sees `Hello, World!` in their browser window. Amazing right?

A quick summary of things to take away from this code review:

 1. blocks can be saved and evaluated later
 2. splat (*) can be used to group parameters into an array
 3. creating rack apps is as simple as having an object with `:call(env)` method that returns a 3 element array!

###### [Interested in seeing a more complex example? Next Lesson ->](/lesson/2)
- - -
Sources:  
<a href="https://github.com/chneukirchen/rum" target="_blank">https://github.com/chneukirchen/rum</a>  
<a href="http://rack.github.io" target="_blank">http://rack.github.io</a>  
<a href="https://github.com/rack/rack" target="_blank">https://github.com/rack/rack</a>  