###Lesson 4

Deploying pure racks apps is straight forward and rewarding. I'll be hand holding you through deploying this for **FREE** on heroku.

- - -

- 1: make a **free** heroku account. This will allow you to spin up as many projects as you want for anyone to use. The only limitation is how much up-time your website will have. It'll sleep every 30 minutes and heroku caps activity at a certain amount of hours. Still pretty good for small projects to share with friends.  
<a href="https://signup.heroku.com/dc" target="_blank">Make an account</a>

- 2: Download and install heroku tools for the command line.  
<a href="https://devcenter.heroku.com/articles/heroku-cli#download-and-install" target="_blank">Heroku CLI Download</a>

- 3: Setup up your local enivorment with heroku.  
Run `heroku login` and enter your credentials  
<a href="https://devcenter.heroku.com/articles/getting-started-with-ruby#set-up" target="_blank">Set-up</a>

- 4: install ruby, if you haven't already for some reason.    
Install ruby

- 5: Get bundler, a popular gem to manage gem's for applications.  
Run this command: `gem install bundler`

- 6: Prepare your app:  
Let's assume this is the rum app you want to deploy:

      require '../lib/rum'
      run Rum.new {
        on default do
          puts 'Hello, World!'
        end
      }
Save that into a file called `config.ru`. Try running it with `rackup config.ru` to double check. If it fails, makes sure `rum.rb` is in the right place or change the `require` call in your app.

- 7: Create a file called `Gemfile`, no extension  
This will contain all gems you need for your app to run. In this case the gemfile can just look like this:

      source 'https://rubygems.org'
      gem 'rack'

- 8: Test it on your machine, with the following command:  

      bundle install
      bundle exec rackup -p 9292 config.ru

If it's not working, double check everything is in the right place in your directory and that you have all the gems you want listed in the Gemfile.

- 9: Install git and if you already have it type the following commands:

      git init
      git add .
      git commit -m 'pure rack app'
      heroku create
      git push heroku master
      heroku open


- 10: You are already done! If you setup everything up properly your browser should have already opened up to show you your app! Sweet!

######<a href="/lesson/5" target="_blank">One last lesson -></a>
- - -
Sources:  
<a href="https://devcenter.heroku.com/articles/rack" target="_blank">https://devcenter.heroku.com/articles/rack</a>