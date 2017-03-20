require './lib/rye'

use Rack::ContentType

run Rum.new {
  on 'lesson', number do |_,n|
    case n.to_i
    when 1; markdown :tutorial
    when 2; markdown :extra
    when 3; markdown :tilt
    when 4; markdown :deploy
    when 5; markdown :repo
    else
      res.redirect('/')
    end
  end
  on 'about' do
    markdown :about
  end
  on 'help' do
    markdown :help
  end
  on root? do
    haml :main
  end
  on default do
    # just redirect to root
  end
}
