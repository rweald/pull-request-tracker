require "spec_helper"

describe GithubIntegration do
  before(:each) do
    @gh = GithubIntegration::APIRequest.new :user => "icl", :repository => "cove", :filepath =>  File.expand_path("~/Computer Programs/cogs120/cove-test") 
    @result = @gh.get_pull_requests()
  end
  
  describe "#get_pull_requests" do
    it "should return all your pull requests" do
      @result.count().should be > 0
    end
  end
  
  describe "#store_new_pull_requests" do
    it "should store request in redis" do
      # @gh = GithubIntegration::APIRequest.new :user => "icl", :repository => "cove"
      @gh.store_new_pull_requests @result
      @gh.redis.llen("test_queue").should be > 0
      @gh.redis.scard("pull_requests").should be > 0
    end
  end
  
  describe "#run_test_suite" do
    before(:each) do
      @gh.run_test_suite("testsuite:sample")
    end
    it "should set cucumber results" do
      @gh.redis.exists("testsuite:sample-cucumber").should be_true
    end
    
    it "should set the rspec results" do
      @gh.redis.exists("testsuite:sample-rspec").should be_true
    end
  end
  
  describe "#parse_rspec_result" do
    it "should return [4,0]" do
      @gh.parse_rspec_result("Finished in 31.81 seconds
      4 examples, 0 failures").should == ["4","0"]

    end
  end
  
  describe "#parse_cucumber_result" do
    it "should return [4,4]" do
      @gh.parse_cucumber_result("4 scenarios (4 passed)").should == ["4", "4"]
      
    end
    
    it "should return [4,3]" do
      @gh.parse_cucumber_result("4 scenarios (1 failed, 3 passed)").should == ["4", "3"]
    end
  end
end