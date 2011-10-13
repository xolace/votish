require 'rubygems'
require 'sinatra'
require 'sinatra/session'
require 'datamapper'
require 'dm-types'

DataMapper::setup(:default, "")
#DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/votish.db")

illegalvote = "Illegal vote. To have your vote counted, text 'BYUHLSH <your vote here>' to 41411"
legalip = ""


class Vote
  include DataMapper::Resource
  property :id, Serial
  property :cell, String
  property :date, DateTime
  property :ip, IPAddress
  belongs_to :singer
  belongs_to :history
end


class Singer
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  has n, :votes

end

class History
  include DataMapper::Resource
  property :id, Serial
  property :legal, Boolean, :default => false
  property :ip, IPAddress
  has n, :votes
end


Singer.auto_migrate! unless Singer.storage_exists?
Vote.auto_migrate! unless Vote.storage_exists?
History.auto_migrate! unless History.storage_exists?


helpers do
  def log(ip)
    inmate = Vote.first(:ip => ip)
    if (inmate.nil?)
      record = History.new
      record.ip = ip
      record.legal = false
      record.save!
    end
  end

end

set :session_fail, '/login'
set :session_secret, 'secretcodehere'

before '/vote/*' do
  log(request.ip)
end

get '/logout' do
  session.delete
  redirect '/'
end

get '/inspect' do
  records = History.first
  "#{records.ip} voted #{records.votes.count} times."
end

get '/vote/:cell/:ballot' do
  check = Vote.first(:cell => "#{params[:cell]}")
  if Singer.get(params[:ballot])
    if check.nil?
      @post = Vote.create(
          :cell => "#{params[:cell]}",
          :singer => Singer.first(:id => "#{params[:ballot].to_i}"),
          :date => Time.now,
          :ip => request.ip,
          :history => History.first(:ip => request.ip)
      )
      @post.save
      @message = "Your vote has been cast for #{@post.singer.name}. Thanks! (Ballot cast from #{@post.cell} (Logged: #{@post.ip} voted #{@post.history.votes.count} times.)"
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
    redirect '/login'
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
    @records = History.all
    erb :admin
  else
    redirect '/login'
  end
end

get '/admin/del/votes/:id' do
  if session?
    reject = History.get(params[:id])
    reject.votes.destroy
    reject.destroy
    @message = "Successfully deleted those scumbag votes"
    @destiny = '/admin'
    erb :redirect
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
      History.auto_migrate!
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
