require 'rubygems'
require 'sinatra'
require 'sinatra/session'
require 'datamapper'

DataMapper::setup(:default, "")
#DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/votish.db")

class Vote
  include DataMapper::Resource
  property :id, Serial
  property :cell, String
  property :date, DateTime
  belongs_to :singer
end


class Singer
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  has n, :votes

  def counting
    puts self.relationships[:votes].inspect
  end

end

Singer.auto_migrate! unless Singer.storage_exists?
Vote.auto_migrate! unless Vote.storage_exists?


class Admin
  include DataMapper::Resource
  property :id, Serial
  property :username, String
  property :password, String
  property :elevation, Integer
end


helpers do

end

set :session_fail, '/login'
set :session_secret, 'secretcodehere'

get '/test' do
  singer = Singer.first
  "#{singer.name} has #{singer.votes.count}"
  puts Singer.relationships[:votes].counting
end

get '/vote/:cell/:ballot' do
  check = Vote.first(:cell => "#{params[:cell]}")
  if Singer.get(params[:ballot])
    if check.nil?
      @post = Vote.create(
          :cell => "#{params[:cell]}",
          :singer => Singer.first(:id => "#{params[:ballot].to_i}"),
          :date => Time.now
      )
      @post.save
      @message = "Your vote has been cast for #{@post.singer.name}. Thanks! (Ballot cast from #{@post.cell})"
    else
      unless check.singer.id == params[:ballot]
        rejected = check.singer.name
        check.update(:singer => Singer.first(:id => "#{params[:ballot].to_i}"))
        check.save
        @message = "Your vote has been changed from #{rejected} to #{check.singer.name}. (Ballot change from #{check.cell})"
      else
        @message = "Your vote for #{check.singer.name} remains unchanged. (The input we received was '#{params[:ballot]})"
      end
    end
  else
    @message = "You have made an invalid selection."
  end
  "#{@message}"
end


get '/del/person/:id' do
  if session?
    erb :del
  else
    redirect '/login'
  end
end

post '/admin/person/delete' do
  if session?
    @person = Singer.first(:id => "#{params[:id].to_i}")
    destroyed = @person.name
    puts @person.votes.destroy
    puts @person.destroy
    @message = "#{destroyed} successfully removed."
    @destiny = "/"
    erb :redirect
  else
    redirect "/login"
  end
end

get '/login' do
  erb :login
end

post '/login' do
  if params[:username] == "admin" && params[:password] = "vitaminwater"
    session_start!
    session[:name] = params[:username]
    redirect '/'
  else
    @destiny = "/login"
    @message = "Your username or password is incorrect."
    erb :redirect
  end
end

get '/' do
  @singers = Singer.all.sort_by { |singer| -singer.votes.count }
  erb :results
end

get '/admin' do
  if session?
    erb :admin
  else
    redirect '/login'
  end
end

post '/admin' do
  if session?
    @destiny = "/admin"
    unless params[:softreset].nil?
      votes = Vote.all
      votes.destroy
      @message = "Tallies have been reset, and validation table cleared. The voting may commence again."

    end
    unless params[:hardreset].nil?
      Vote.auto_migrate!
      Singer.auto_migrate!
      @message = "Clean as a baby's bottom. Everything has been erased. Everything."
    end
  else
    redirect '/login'
  end
  erb :redirect
end

get '/admin/person/add' do
  if session?
    erb :add
  else
    redirect '/login'
  end

end

post '/admin/person/add' do
  if session?
    @person = Singer.new(:name => "#{params[:name]}")
    @person.save
    @destiny = "/"
    @message = "You have sucessfully added #{@person.name}"
    erb :redirect
  else
    @destiny = "/login"
    @message = "Permission denied"
  end
end 
