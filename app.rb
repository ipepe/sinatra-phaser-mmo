require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'coffee-script'
require 'tilt/coffee'
require 'pry'

set :server, 'thin'
set :sockets, []
set :sockets_to_players, {}

def send_event(event, attributes = nil)
  raise ArgumentError unless event.is_a? String
  raise ArgumentError if event.nil?
  EM.next_tick { settings.sockets.each{ |s| s.send(JSON.generate({event: event, attributes: attributes })) } }
end

def read_message(msg)
  response = JSON.parse(msg)
  puts response
  [response['event'], response['attributes']]
end

get '/' do
  if request.websocket?
    request.websocket do |ws|
      ws.onopen do |msg|
        settings.sockets << ws
      end
      ws.onmessage do |msg|
        event, attributes = read_message(msg)
        if event == 'player_create'
          settings.sockets_to_players[attributes['name']] = ws
        end
        send_event(event, attributes)
      end
      ws.onclose do
        unless settings.sockets_to_players.key(ws).nil?
          send_event('player_destroy', { name: settings.sockets_to_players.key(ws), _destroy: true})
        end
        settings.sockets.delete(ws)
      end
    end
  else
    redirect '/index.html'
  end
end



get '/game.js' do
  coffee :game
end

get '/isocket.js' do
  coffee :isocket
end

set :port, 3000
set :bind, '0.0.0.0'
