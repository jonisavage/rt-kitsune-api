#!/usr/bin/env ruby
require 'json'
require 'rubygems'
require 'awesome_print'
require 'time'
require 'date'
require 'mongo'
require 'logger'
require 'launchy'

logger = Logger.new(STDERR)
logger.level = Logger::DEBUG
Mongo::Logger.logger.level = Logger::FATAL
MONGO_HOST = ENV["MONGO_HOST"]
raise(StandardError,"Set Mongo hostname in ENV: 'MONGO_HOST'") if !MONGO_HOST
MONGO_PORT = ENV["MONGO_PORT"]
raise(StandardError,"Set Mongo port in ENV: 'MONGO_PORT'") if !MONGO_PORT
MONGO_USER = ENV["MONGO_USER"]
# raise(StandardError,"Set Mongo user in ENV: 'MONGO_USER'") if !MONGO_USER
MONGO_PASSWORD = ENV["MONGO_PASSWORD"]
# raise(StandardError,"Set Mongo user in ENV: 'MONGO_PASSWORD'") if !MONGO_PASSWORD
SUMO_QUESTIONS_DB = ENV["SUMO_QUESTIONS_DB"]
raise(StandardError,\
      "Set SUMO questions  database name in ENV: 'SUMO_QUESTIONS_DB'") \
if !SUMO_QUESTIONS_DB

db = Mongo::Client.new([MONGO_HOST], :database => SUMO_QUESTIONS_DB)
if MONGO_USER
  auth = db.authenticate(MONGO_USER, MONGO_PASSWORD)
  if !auth
    raise(StandardError, "Couldn't authenticate, exiting")
    exit
  end
end

if ARGV.length < 6
  puts "usage: #{$0} yyyy mm dd yyyy mm dd" # time range you want to open
  exit
end

questionsColl = db[:questions]
MIN_DATE = Time.local(ARGV[0].to_i, ARGV[1].to_i, ARGV[2].to_i, 0, 0) # may want Time.utc if you don't want local time
MAX_DATE = Time.local(ARGV[3].to_i, ARGV[4].to_i, ARGV[5].to_i, 23, 59) # may want Time.utc if you don't want local time

number_solved_for_this_time_period = 0
questionsColl.find(:created =>
  {
    :$gte => MIN_DATE,
    :$lte => MAX_DATE },
  ).sort(
  {"id"=> 1}
  ).projection(
  {
    "id" => 1,
    "created" => 1,
    "solved_by" => 1, 
    "creator" => 1,
    "solution" => 1 
  }).each do |q|
  id = q["id"]
  logger.debug "QUESTION id:" + id.to_s
  creator_username = q["creator"]["username"]
  logger.debug "creator_username:" + creator_username
  solved_by = q["solved_by"]
  next if solved_by.nil?
  solved_by_username = solved_by["username"]
  logger.debug "solved_by_username:" + solved_by_username
  solution = q["solution"]  
  if solved_by_username != creator_username 
    Launchy.open("http://support.mozilla.org/questions/" + id.to_s + "#answer-" + solution.to_s)
    logger.debug "Solution URL:" + "http://support.mozilla.org/questions/" + id.to_s + "#answer-" + solution.to_s
    number_solved_for_this_time_period += 1
    sleep(0.5)
  end
end
logger.debug "Number solved FROM:"  + ARGV[0] + ARGV[1] + ARGV[2] + "TO:" + ARGV[3] + ARGV[4] + ARGV[5] +
            "is:" + number_solved_for_this_time_period.to_s
    
