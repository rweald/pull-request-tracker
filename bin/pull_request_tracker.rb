#!/usr/bin/env ruby

require "rubygems"
require "thor"
# add my custom loadpath
$LOAD_PATH << File.expand_path("../lib/")
require "github_integration_script.rb"
include GithubIntegration

class TrackPullRequests < Thor
  desc "start SOURCEPATH", "run the tracker where SOURCEPATH is the base directory where the master branch resides"
  def start(sourcepath)
    GithubIntegration::Runner.start sourcepath
  end
end
TrackPullRequests.start
