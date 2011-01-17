require "spec_helper"
describe "GithubIntegration" do
  describe "#get_pull_requests" do
    it "should return all your pull requests" do
      GithubIntegration.get_pull_requests.count().should == 1
    end
  end
end