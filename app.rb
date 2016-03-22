require 'sinatra'
require 'json'
require 'coffee-script'

get '/' do
  redirect '/index.html'
end

get '/game.js' do
  content_type "text/javascript"
  coffee :game
end
