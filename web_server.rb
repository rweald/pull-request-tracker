require "rubygems"
require "sinatra"
require "haml"
require "sass"
require "redis"
require "json"

set :haml, :format => :html5


get "/" do
  @pull_requests = []
  db = Redis.new
  pulls = db.smembers "pull_requests"
  pulls.each do |req|
    req = JSON.parse(req)
    label = req["head"]["label"]
    rspec_res = JSON.parse(db.get("#{label}-rspec"))
    cuc_res = JSON.parse(db.get("#{label}-cucumber"))
    @pull_requests << {:label => label, :rspec => rspec_res, :cucumber => cuc_res}
  end
  haml :index
end

get '/stylesheet.css' do
  scss :stylesheet
end

helpers do
  def draw_chart(args)
    array = args[:array]  
    total = array[0].to_i
    success = array[1].to_i
    if args[:rspec]
      success = total - success
    end
    html = "<p> <b> #{total} </b> Tests Run <b> #{success}</b> Test Passed </p>"
    html << '<div class="chart_container" style="width: 500px; height: 40px; background-color:red;">' 
    html << "<div class='chart' style='background-color: green; height: 100%; width: #{(Float(success)/Float(total)) * 100 }%'> </div>"
    html << "</div>"
  end
  
end