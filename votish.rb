require 'rubygems'
require 'sinatra'
require 'datamapper'
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

#this is a hotfix
#this is a cdawg comment

class Vote
  include DataMapper::Resource
  property :id, Serial
  property :cell, String
  property :vote, String
  property :date, DateTime
  has n, :singerID
  belongs_to :singer :through => :singerId
end

Vote.auto_migrate! unless Vote.storage_exists?

class Singer
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :smscode, String
end
Singer.auto_migrate! unless Singer.storage_exists?

helpers do
  def check(cell,vote)
    post = Post.first_or_create({:cell => "#{cell}"}, {
      :cell => "#{cell}",
      :vote  => "#{vote}",
      :date => Time.now
    })
    puts post.save
    "You have succesfully added your vote. #{cell} #{vote}"
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
  puts "HELLO MISTER"
  "#{params[:name]}'s voting code is #{singer.id}"
end

get '/list' do
  singers = Singer.all
  erb :list
end
  

