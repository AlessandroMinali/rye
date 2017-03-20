require './lib/rum'

use Rack::ContentType

run Rum.new {
  on param("name") do |name|
    erb 'Hello, <%= user %> at <%= Time.now %>',
        locals: { user: name }
  end
  on path('haml') do
  	haml :index
  end
  on default do
    markdown "#Hello\n##World"
  end
}