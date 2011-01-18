#!/usr/bin/env ruby
require "rubygems"
require "rest-client"
require "redis"
require "json"
require "fileutils"


module GithubIntegration
  GITHUB = "http://github.com/api/v2/json/pulls"
  FILEPATH = File.expand_path("~/Computer Programs/cogs120/cove-test")
  
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
        if (@redis.sadd "pull_requests", JSON.generate(req))
          @redis.lpush "test_queue", JSON.generate(req)
        end
      end
    end
    
    def run_test_suite(title)
      FileUtils.cd(FILEPATH)
      `bundle install`
      `rake db:migrate`
      result = `rspec --format d spec/`
      parsed_result = self.parse_rspec_result result
      @redis.set "#{title}-rspec" , "#{JSON.generate(parsed_result)}"
      
      result = `rake cucumber`
      parsed_result = self.parse_cucumber_result result
      @redis.set "#{title}-cucumber" , "#{JSON.generate(parsed_result)}"
    end
    
    def parse_rspec_result(result)
      saved_result = []
      result = result.split("seconds")[1]
      result = result.split(",")
      result.each do |entry|
        saved_result << entry.strip.split(" ")[0]
      end
     return saved_result
    end
    protected :parse_rspec_result
    
    def parse_cucumber_result(result)
      saved_result = []
      res = result.match(/([0-9]+) scenarios \(.*,? ([0-9]+) passed\)/).captures
      if res
        return res
      else
        return result.match(/([0-9]+) scenarios \(([0-9]+) passed\)/).captures
      end
    end
    protected :parse_cucumber_result
    
    def checkout_pull_request(args)
      FileUtils.cd(FILEPATH)
      uname = args[:user_name]
      bname = args[:branch_name]
      cmd_string = "git checkout -b #{uname}-#{bname} master"
      system(cmd_string)
      cmd_string = "git pull git://github.com/#{uname}/#{@repository}.git #{args[:branch_name]}"
      system(cmd_string)
    end
  end
end