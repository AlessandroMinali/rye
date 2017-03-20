### Troubleshooting

#### Errors

You are probably missing gems. Here is a list of all the gems you need to install to get through all the excerises:

	gem 'rack'
	gem 'tilt'
	gem 'rdiscount'
	gem 'haml'
	gem 'erubis'

#### Don't know where to put code?

Here is all custom code discussed in the excerises: [code]()

#### Deploy Issues

- [Install Heroku](https://devcenter.heroku.com/articles/heroku-cli#download-and-install)
- Make sure you have a Gemfile with all the above gems listed
- Make sure your app is inside a file called `config.ru`
- To get yo your page use the command `heroku open`, cool huh?