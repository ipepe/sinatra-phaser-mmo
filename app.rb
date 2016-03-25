require 'json'
require 'coffee-script'
require 'tilt/coffee'
require 'em-websocket'
require 'sinatra/base'
require 'thin'

class App < Sinatra::Base
  # set :threaded, true
  class << self
    attr_accessor :sockets
    attr_accessor :sockets_to_players
  end
  def self.send_event(event, attributes = nil)
    raise ArgumentError unless event.is_a? String
    raise ArgumentError if event.nil?
    EventMachine.next_tick do
      App.sockets.each do |s|
        s.send(JSON.generate({event: event, attributes: attributes}))
      end
    end
  end

  def self.read_message(msg)
    response = JSON.parse(msg)
    puts response
    [response['event'], response['attributes']]
  end

  get '/' do
    redirect '/index.html'
  end

  get '/game.js' do
    coffee :game
  end

  get '/isocket.js' do
    coffee :isocket
  end
end

App.sockets = []
App.sockets_to_players = {}

unless EM.reactor_running?
  Thread.new do
    EventMachine.run do
      EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
        ws.onopen do |msg|
          App.sockets << ws
        end
        ws.onmessage do |msg|
          event, attributes = App.read_message(msg)
          if event == 'player_create'
            App.sockets_to_players[attributes['name']] = ws
          end
          App.send_event(event, attributes)
        end
        ws.onclose do
          unless App.sockets_to_players.key(ws).nil?
            App.send_event('player_destroy', {name: App.sockets_to_players.key(ws), _destroy: true})
          end
          App.sockets.delete(ws)
        end
      end
    end
  end
end

