require 'net/http'
require 'hpricot'
require 'yaml'

module LighthouseImporter

  class Bugzilla
    def self.import
      
      @config = YAML.load_file('config.yaml')
      
      doc = Hpricot.XML(File.read(@config['file']))
      bugs = (doc/:bug)
      
      bugs.each do |b|
        # Build out the XML ticket.
        body = ""
        body << "<ticket>\n"
        body << " <assigned-user-id type=\"integer\">#{user((b/"assigned_to").innerHTML)}</assigned-user-id>\n"
        body << " <title>#{(b/"short_desc").innerHTML}</title>\n"
        body << " <state>#{status((b/"bug_status").innerHTML)}</state>\n"
        body << " <body>#{((b/"long_desc").first/"thetext").innerHTML}</body>\n"
        body << " <milestone-id type=\"integer\">#{milestone((b/"version").innerHTML)}</milestone-id>\n"
        body << "</ticket>"
        
        puts body
      
        # POST to tickets.xml
        url = URI.parse("http://#{@config['account']}.lighthouseapp.com/projects/#{@config['project']}/tickets.xml")  
        req = Net::HTTP::Post.new(url.path)
        
        headers = {'X-LighthouseToken' => "#{@config['token']}",
                  'Content-Type' => 'application/xml'}
        http = Net::HTTP.new(url.host, url.port)
        res = http.post(url.path, body, headers)
        
        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          puts "Posted bugzilla bug #{(b/"bug_id").innerHTML}"
        else
          res.error!
        end

      end
    end
  
    def self.status(status)
      if status == "RESOLVED"
        "resolved"
      else
        "open"
      end
    end
  
    def self.milestone(milestone)
      @config['milestones']["#{milestone}"]
    end
  
    def self.user(email)
      @config['users']["#{email}"]
    end
  end
end