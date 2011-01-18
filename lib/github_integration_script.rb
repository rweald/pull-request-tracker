#!/usr/bin/env ruby
require "rubygems"
require "rest-client"
require "redis"
require "json"
require "fileutils"


module GithubIntegration
  GITHUB = "http://github.com/api/v2/json/pulls"
  # FILEPATH = File.expand_path("~/Computer Programs/cogs120/cove-test")
  
  class APIRequest
    attr_accessor :redis
    attr_accessor :user
    attr_accessor :repository
    attr_accessor :filepath
    def initialize(args)
      @user = args[:user]
      @repository = args[:repository]
      @filepath = args[:filepath]
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
        if (@redis.sadd "labels", req["head"]["label"])
          @redis.sadd "pull_requests", JSON.generate(req)
          @redis.lpush "test_queue", JSON.generate(req)
        end
      end
    end
    
    def run_test_suite(title)
      FileUtils.cd(@filepath)
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
      # saved_result = []
      # result = result.split("seconds")[1]
      # result = result.split(",")
      # result.each do |entry|
      #   saved_result << entry.strip.split(" ")[0]
      # end
     # return saved_result
     return result.match(/([0-9]+) examples, ([0-9]+) failures/).captures
    end
    # protected :parse_rspec_result
    
    def parse_cucumber_result(result)
      res = result.match(/([0-9]+) scenarios \(.*,? ([0-9]+) passed\)/)
      if res
        return res.captures
      else
        return result.match(/([0-9]+) scenarios \(([0-9]+) passed\)/).captures
      end
    end
    # protected :parse_cucumber_result
    
    def checkout_pull_request(args)
      FileUtils.cd(@filepath)
      uname = args[:user_name]
      bname = args[:branch_name]
      cmd_string = "git checkout -b #{uname}-#{bname} master"
      system(cmd_string)
      cmd_string = "git pull git://github.com/#{uname}/#{@repository}.git #{args[:branch_name]}"
      system(cmd_string)
    end
  end
  
  class Runner
    def self.start(filepath)
      g = GithubIntegration::APIRequest.new :user => "icl", :repository => "cove", :filepath => filepath

      # get the requests 
      g.store_new_pull_requests(g.get_pull_requests)

      while (g.redis.llen("test_queue") > 0)
        req = JSON.parse(g.redis.lpop("test_queue"))
        req = req["head"]
        g.checkout_pull_request :branch_name => req["ref"], :user_name => req["repository"]["owner"], :url => req["repository"]["url"]
        g.run_test_suite req["label"]
      end
      puts "This is proof that I have been run"
    end
  end
end