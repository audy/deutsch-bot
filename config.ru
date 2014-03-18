require './environment.rb'

Bundler.require :web

class Application < Sinatra::Base
  get "/" do
    @words = GermanWord.all
    erb "<ul><% @words.each do |w| %><li><em><%= w.article %></em> <strong><%= w.word %></strong> - <%= w.definition %></li><% end %></ul>"
  end
end

Application.run! :port => 9998
