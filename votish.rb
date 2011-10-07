require 'rubygems'
require 'sinatra'
require 'datamapper'
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Vote
  include DataMapper::Resource
  property :id, Serial
  property :cell, String
  property :ballot, String
  property :date, DateTime
  
end

Vote.auto_migrate! unless Vote.storage_exists?

class Singer
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :tally, Integer , :default => 0
end

Singer.auto_migrate! unless Singer.storage_exists?

helpers do
  def check(cell,ballot)
    post = Vote.create(
      :cell => "#{cell}",
      :ballot  => "#{ballot}",
      :date => Time.now
       )
    puts post.ballot
    "It worked! #{post.ballot}"
  end

end

get '/vote/:cell/:ballot' do
     check = Vote.first( :cell => "#{params[:cell]}" )
     if check.nil?
     singer = Singer.first( :id => "#{params[:ballot].to_i}" )
     puts singer.inspect
     post = Vote.create(
      :cell => "#{params[:cell]}",
      :ballot  => "#{params[:ballot]}",
      :date => Time.now
       )
    singer.tally += 1
    puts singer.save
    puts post.save
    "We have added your vote: #{post.cell} for #{post.ballot}"
    else
    "Vote rejected, nice try though"
    end
end


get '/add/:name' do
  singer = Singer.first_or_create({ :name => "#{params[:name]}" }, {
    :name => "#{params[:name]}",
  })
  puts singer.save
  "#{params[:name]}'s voting code is #{singer.id}"

end

get '/results' do
   @singers = Singer.all
   erb :results
   end

get '/add' do
  erb :add
end

post '/create' do 
  @person = Singer.new( :name => "#{params[:name]}" )
  @person.save
  erb :create
end 
