#!/usr/bin/env ruby
require "rubygems"
require "rest-client"
require "redis"
require "json"

# class ClassName
#   attr_accessor :user
#   attr_accessor :repository
#   attr_reader :redis
# 
#   def initialize(args)
#     @user = args[:user]
#     @repository = args[:repository]
#     @redis = Redis.new
#   end
#   
#   def get_pull_requests
#     requests = RestClient.get "#{GITHUB}/#{@user}/#{@repository}"
#     self.store_unseen_requests requests
#   end
#   
#   private
#   def store_unseen_requests(requests)
#     requests.each do |req|
#       if !(@redis.sadd "pull_requests", req)
#         @redis.lpush "unprocessed", req
#       end
#     end
#   end
# end


module GithubIntegration
  GITHUB = "http://github.com/api/v2/json/pulls"
  FILEPATH = File.expand_path("~/Computer Programs/cogs120/snack-picker-test")
  
  def self.init
    @user = "rweald"
    @repository = "snack-picker"
  end
  
  def self.get_pull_requests
    self.init
    route = "#{GITHUB}/#{@user}/#{@repository}/closed"
    response = RestClient.get route
    pull_requests = JSON.parse(response)
    return pull_requests["pulls"]
    # self.store_unseen_requests requests
  end
end