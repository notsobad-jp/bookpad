require 'bundler'
Bundler.require
require './lib/app_metric'

require './main'
run Sinatra::Application
