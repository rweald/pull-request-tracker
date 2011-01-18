require "github_integration_script.rb"

RSpec.configure do |config|
  config.before(:suite) do 
    r = Redis.new
    r.keys.each do |key|
      r.del key
    end
  end
end