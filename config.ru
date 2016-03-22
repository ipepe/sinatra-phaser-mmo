require 'rubygems'
require 'bundler'

Bundler.require

require './app'

set :run, false
set :environment, :development

run Sinatra::Application

