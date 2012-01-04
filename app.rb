require 'sinatra'
require 'slim'
require 'coffee-script'
require 'sass'

get '/' do
  slim :index
end

get '/javascripts/app.js' do
  coffee :app
end

get '/stylesheets/style.css' do
  scss :style
end
