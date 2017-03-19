require './lib/rum'

use Rack::ContentType

run Rum.new {
  on default do
    markdown '#Coming Soon'
  end
}
