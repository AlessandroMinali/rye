So now that we are masters at understanding how [rum](https://github.com/chneukirchen/rum) works, let's try to customize it with some features. In this tutorial I'll be adding the following to rum:

 1. Add support for HTML templates
 2. Add support for view partials

Grab the [rum repo from github](https://github.com/chneukirchen/rum) and let's start changing the source code!
- - -
In the land of ruby there are tons of different HTML templating languages. Some of the most popular are [erb](https://ruby-doc.org/stdlib-2.4.0/libdoc/erb/rdoc/ERB.html) (the default for rails) and [haml](http://haml.info). [Markdown](https://en.wikipedia.org/wiki/Markdown) is another general purpose markup which is used everywhere on the web (even this page ☺ ). Let's add all three!

We will use the [tilt gem](https://github.com/rtomayko/tilt) to make this relatively easy. Tilt provides a simple interface to hook up a ton of templating engines with very little effort.

    require 'tilt'

    template =  Tilt::ErubisTemplate.new do
      "Hello <%= name %>!"
    end
    puts template.render( self, name: 'World' )

This is basically all the code you need to get `erb` templates up and running. I want the functionality of our templates to be a little nicer to use. I want a typical template call to look like:

    erb '<h1>Welcome</h1><b><%= name %></b>
This is similar to what you find in other frameworks, like rails.  So what I'll do is iterate over the three template I want available and define methods for each.

    {'erb': Tilt::ErubisTemplate, 'haml': Tilt::ErubisTemplate, 'markdown': Tilt::RDiscountTemplate}.each do |k,v|
      define_method k do |text, *args|
        template = v.new(*args) do
          text
        end
        locals = (args[0].respond_to?(:[]) ? args[0][:locals] : nil) || {} 
        res.write template.render(self, locals)
      end
    end
This is added to the end of the **Rum** class.  I have a hash of `method names` and `template engines` that I want to associate.  For each `method name` I define a dynamic method that creates `:new` template with text that I pass in. I also can pass in locals as well since we lose the proper scope. I call `:render` and finally I write directly to the **Rack::Response** object! Here it is in action:

	require '../lib/rum'
	run Rum.new {
	  on param("name") do |name|
	    erb 'Hello, <%= user %> at <%= Time.now %>',
	    	locals: { user: name }
	  end
	  on default do
	    markdown "#Hello\n##World"
	  end
	}

Now that I can use tempting languages, I would like to be able to write them out in separate files so I can keep my app uncluttered. To do this I'll make a helper method that finds and grabs view partials from a different folder folder.

    def find_partial(content)
      return content if content.is_a? String
      File.open(Dir["views/#{content}\.*"][0]).read
    end
    .
    .
         template = v.new(*args) do
           find_partial text
         end
    .
    .

This new method `:find_partial` will look for a file in the `/views` folder and grab the first one the matches, regardless of the extension. We allow the options to still use inline text with our template methods. In order to make use of this functionality we need to make sure to call this method within our dynamic methods creation loop. To test it I create a folder called `/views` and save the following into `views/index.haml`:

    %h1 Test
    %hr
    %p Partials are working, hurray!

Now I can use `haml :index` or `haml 'index'` to automagically grab the view and render it!

Pretty cool, huh? Now go crazy and build a fully fleshed out app with different routes and partials!

[Wondering how to deploy this app onto the internet? Right this way ->]()
- - -
Sources:
http://planetruby.github.io/gems/tilt.html

