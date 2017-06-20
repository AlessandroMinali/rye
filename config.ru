require './lib/rye'

# used to serve 'text/html' content
use Rack::ContentType

run Rye.new {
  # these routes are super simple, just a string!
  # this is accomplished by checking on line 43 of rye.rb
  # saves me the effort of typing out path('lesson')
  on 'lesson', number do |_, n|
    case n.to_i
    when 1 then markdown :tutorial
    when 2 then markdown :extra
    when 3 then markdown :tilt
    when 4 then markdown :deploy
    when 5 then markdown :repo
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
