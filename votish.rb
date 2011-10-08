require 'sinatra'
require 'datamapper'

DataMapper::setup(:default, "postgres://mjdlunpvrl:4IV0PaQ5jYG3L7ygi9AQ@ec2-107-20-192-196.compute-1.amazonaws.com/mjdlunpvrl")

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
    "We have added your vote: #{post.cell} for #{post.ballot} (#{singer.name}). The current tally for #{singer.name} is #{singer.tally} votes."
    else
    singer = Singer.first( :id => "#{params[:ballot].to_i}" )
    rejected = Singer.first( :id => "#{check.ballot.to_i}" )
    rejected.tally -= 1;
    singer.tally += 1;
    rejected.save
    singer.save
    "Vote changed for this number has changed from #{rejected.name} (Votes: #{rejected.tally}) to #{singer.name} (Votes: #{singer.tally}). These tallies reflect your change of vote."
    end
end


get '/del/person/:id' do
  erb :del
end

post '/admin/person/delete' do
  if params[:password] == "vitaminwater"
  @person = Singer.first( :id => "#{params[:id].to_i}" )
  erb :rem
  @person.destroy
  else
  "Permission denied"
end
end

get '/' do
   @singers = Singer.all(:order => [:tally.desc ] )
   erb :results
   end

get '/admin' do
  erb :admin
end

post '/admin' do
  if params[:password] == "vitaminwater"
    unless params[:softreset].nil?
      singers = Singer.all
      votes = Vote.all
      singers.each do |singer|
        singer.tally = 0
	singer.save
      end
      votes.destroy
      "Tallies have been reset, and validation table cleared. The voting may commence again."
    end
   unless params[:hardreset].nil?
     Vote.auto_migrate!
     Singer.auto_migrate!
     "Clean as a baby's bottom. Everything has been erased. Everything."
   end
  else
    "Permission denied"
  end
end

get '/admin/person/add' do
  erb :add
end

post '/admin/person/add' do 
  if params[:password] == "vitaminwater"
  @person = Singer.new( :name => "#{params[:name]}" )
  @person.save
  erb :create
  else
  "Permission denied"
  end
end 
