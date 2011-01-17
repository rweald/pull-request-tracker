#!/usr/bin/env ruby
require "rubygems"
require "rest-client"
require "redis"
require "json"
require "fileutils"


module GithubIntegration
  GITHUB = "http://github.com/api/v2/json/pulls"
  FILEPATH = File.expand_path("~/Computer Programs/cogs120/snack-picker-test")
  
  class APIRequest
    attr_accessor :redis
    attr_accessor :user
    attr_accessor :repository
    def initialize(args)
      @user = args[:user]
      @repository = args[:repository]
      @redis = Redis.new
    end
    
    def get_pull_requests
      route = "#{GITHUB}/#{@user}/#{@repository}"
      response = RestClient.get route
      pull_requests = JSON.parse(response)
      return pull_requests["pulls"]
      # self.store_unseen_requests requests
    end
    
    def store_new_pull_requests(pull_requests)
      pull_requests.each do |req|
        if (@redis.sadd "pull_requests", req)
          @redis.lpush "test_queue", req
        end
      end
    end
    
    def run_test_suite
      FileUtils.cd(FILEPATH)
      result = `rspec --format d spec/`
      saved_result = []
      result = result.split("seconds")[1]
      result = result.split(",")
      result.each do |entry|
        saved_result << entry.strip.split(" ")[0]
      end
      @redis.lpush "results" , "#{result = result.split(",")}"
    end
    
    
    def checkout_pull_request(args={})
      FileUtils.cd(FILEPATH)
      cmd_string = "git checkout -b #{args[:branch_name]}:#{args[:user_name]} master"
      system(cmd_string)
      cmd_string = "git pull #{args[:url]} #{args[:branch_name]}"
      system(cmd_string)
    end
  end
end