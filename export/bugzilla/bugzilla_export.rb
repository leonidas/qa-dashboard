require 'rubygems'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'date'
require 'bundler'
require 'yaml'
Bundler.require(:default)

POLLING_PERIOD = 30 #in secs
EXPORT_RANGE   = 3  #in days

LAST_EXPORT_DUMP = Dir.pwd + "/bugzilla_last_export_array.yml"
            
BUGZILLA_CONFIG  = YAML.load_file("bugzilla_config.yml")
POST_API_CONFIG  = YAML.load_file("post_api_config.yml")

DAEMONIZE_OPTIONS = {
    :log_output => true,
    :multiple => false,
    :monitor => true
}

def daemonize
    Daemons.run_proc('bugzilla_exportd', DAEMONIZE_OPTIONS) do
        loop do
            puts "--- Polling round started: " + Time.now.to_s + " ---"

            # get bugzilla data
            fromdate = (Date.today-EXPORT_RANGE).to_s
            fromdate = "" unless File.exist?(LAST_EXPORT_DUMP) #full export if last export not known
            data_array = parse_bugzilla_csv(export_bugzilla_csv(fromdate))
            puts data_array.size.to_s + " bug reports exported"

            # calculate delta since last export
            delta = data_array - read_array_from_file(LAST_EXPORT_DUMP)

            # send data 
            if not delta.empty?
                puts delta.size.to_s + " bug reports to update" 
                postdata = { "token" => POST_API_CONFIG['apitoken'], "bugs" => delta }
                #puts postdata.to_json unless fromdate == "" #debug
                response = RestClient.post POST_API_CONFIG['uri'], postdata.to_json, :content_type => :json, :accept => :json
                puts response.to_str
                dump_array_to_file(LAST_EXPORT_DUMP, data_array)
            else
                puts "nothing to update"
            end

            # polling wait
            sleep(POLLING_PERIOD)
        end
    end
end


def export_bugzilla_csv(fromdate="", todate="Now")

    # Include export range in uri
    todate   = "&chfieldto=" + todate
    fromdate = "&chfieldfrom=" + fromdate unless fromdate == ""

    uri = BUGZILLA_CONFIG['uri'] + fromdate + todate

    # Export bugzilla CSV
    content = ""
    @http = Net::HTTP.new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    @http.use_ssl = BUGZILLA_CONFIG['use_ssl']
    @http.start() do |http|
        req = Net::HTTP::Get.new(uri)
        if not BUGZILLA_CONFIG['http_username'].nil?
            req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
        end
        response = http.request(req)
        content = response.body
    end
    content
end


def parse_bugzilla_csv(content)
    data_array = []    
    FasterCSV.parse(content, :headers => true) do |row|
        row = row.to_hash
        #customize data
        row["weeknum"]  = Date.parse(row["opendate"]).cweek
        row["opendate"] = Time.parse(row["opendate"]).utc
        data_array.push(row)
    end
    data_array
end


def read_array_from_file(filename)
    return [] if not File.exist?(filename)
    stored_array = YAML.load(File.open(filename)) 
end


def dump_array_to_file(filename, data)
    File.open(filename,"w") { |out| out << data.to_yaml }
end

# start script
daemonize

