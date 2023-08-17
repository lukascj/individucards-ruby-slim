require 'sinatra'
require 'slim'
require 'rerun'

get '/' do
    slim(:login)
end

get '/game' do
    slim(:game)
end