require 'rubygems'
require 'sinatra'
require 'datamapper'
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Vote
  include DataMapper::Resource
  property :id, Serial
  property :cell, String
  property :date, DateTime
  
end

Vote.auto_migrate! unless Vote.storage_exists?

class Singer
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :tally, Integer
end

Singer.auto_migrate! unless Singer.storage_exists?

helpers do
  def check(cell,vote)
    post = Vote.first_or_create({:cell => "#{cell}"}, {
      :cell => "#{cell}",
      :vote  => "#{vote}",
      :date => Time.now
    })
    puts post.save
    "You have succesfully added your vote. #{post.cell} #{post.vote}"
  end

end

get '/vote/:cell/:vote' do
  check(params[:cell],params[:vote])
end


get '/add/:name' do
  singer = Singer.first_or_create({ :name => "#{params[:name]}" }, {
    :name => "#{params[:name]}",
  })
  puts singer.save
  "#{params[:name]}'s voting code is #{singer.id}"
end

get '/list' do
  unless Singer.empty? 
  @singers = Singer.all
  #"This should print. #{@singers.inspect}"
  @singers.each do | singer |
  "[#{singer.name}] (#{singer.id}) => #{singer.tally}"
end
end
end

