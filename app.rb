require 'sinatra'
require 'json'
require 'coffee-script'
require 'tilt/coffee'

get '/' do
  redirect '/index.html'
end

get '/game.js' do
  content_type "text/javascript"
  coffee :game
end

set :port, 3000
set :bind, '0.0.0.0'
