require 'bundler'
Bundler.require
use AppMetric

require './main'
run Sinatra::Application
