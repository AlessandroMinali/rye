### Troubleshooting

#### Errors

You are probably missing gems. Here is a list of all the gems you need to install to get through all the excerises:

	gem 'rack'
	gem 'tilt'
	gem 'rdiscount'
	gem 'haml'
	gem 'erubis'

#### Template Issue

###### My page looks funny (html tags everywhere)

Add this to your rack app:

	use Rack::ContentType

#### Don't know where to put code?

Here is all custom code discussed in the excerises: <a href="https://github.com/AlessandroMinali/rye" target="_blank">code</a>

#### Deploy Issues

######Common Pitfalls (in no particular order)
- <a href="https://devcenter.heroku.com/articles/heroku-cli#download-and-install" target="_blank">Install Heroku</a>
- Make sure you have a Gemfile with all the above gems listed
- Make sure your app is inside a file called `config.ru`
- To get your page use the command `heroku open`, cool huh?