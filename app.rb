require 'sinatra'
require 'json'
require 'coffee-script'
require 'tilt/coffee'

set :server, 'thin'
set :sockets, []

get '/' do
  if !request.websocket?
    redirect '/index.html'
  else
    request.websocket do |ws|
      ws.onopen do |msg|
        puts msg
        ws.send("Hello World!")
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        EM.next_tick { settings.sockets.each{ |s| s.send(msg) } }
      end
      ws.onclose do
        warn("wetbsocket closed")
        settings.sockets.delete(ws)
      end
    end
  end
end



get '/game.js' do
  content_type "text/javascript"
  coffee :game
end

set :port, 3000
set :bind, '0.0.0.0'
