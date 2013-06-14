require 'bundler/setup'

Bundler.require(:default)

require 'sinatra/config_file'
require 'sinatra/reloader'

require File.join(File.dirname(__FILE__), 'server')

Rack::Handler::Thin.run Application::Main, :Port => 5000
