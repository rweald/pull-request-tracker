require "rubygems"

require "redis"
require "JSON"
require "ruby-debug"
$LOAD_PATH.push("/Users/Ryan/Computer Programs/cogs120/pull-tracker/lib")
require "github_integration_script.rb"

include GithubIntegration

g = GithubIntegration::APIRequest.new :user => "icl", :repository => "cove"

# get the requests 
g.store_new_pull_requests(g.get_pull_requests)

while (g.redis.llen("test_queue") > 0)
  req = JSON.parse(g.redis.lpop("test_queue"))
  req = req["head"]
  g.checkout_pull_request :branch_name => req["ref"], :user_name => req["repository"]["owner"], :url => req["repository"]["url"]
  
  g.run_test_suite req["label"]
end

