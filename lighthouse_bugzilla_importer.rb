require 'net/http'
require 'utilities'
require 'extensions'
require 'hpricot'

module LighthouseImporter
  include Lighthouse
  
  CONFIG = YAML.load_file('config.yml')

  class Bugzilla
    def self.import
    
      self.init
      
      # Assignee
      # ["bmoran@onehub.com", "cmount@onehub.com", "lcaplan@onehub.com", "loe@onehub.com", "manderson@onehub.com", "mtierney@onehub.com", "rmckown@onehub.com", "lmoudy@onehub.com", "bcaplan@onehub.com", "hegde_mg@spanservices.com", "robertrevans@gmail.com", "stickmanlabs@gmail.com", "swalker@onehub.com"]
      
      # Reporter
      # ["bmoran@onehub.com", "cmount@onehub.com", "manderson@onehub.com", "bcaplan@onehub.com", "lmoudy@onehub.com", "rmckown@onehub.com", "swalker@onehub.com", "mtierney@onehub.com", "lcaplan@onehub.com", "loe@onehub.com"]
              
      @bugs.each do |b|
        tags = []
        
        # Get the items we're interested in.
        
        # Priority
        priority = (b/:priority).first.innerHTML.downcase
        tags << "pri:#{priority.gsub("p", "")}"
        
        # Component
        component = (b/:component).first.innerHTML.downcase.split.join('_')
        tags << component
        
        # Milestone
        milestone_name = (b/:version).first.innerHTML
        milestone      = @project.find_or_create_milestone(:title => milestone_name)
        
        # Severity
        severity = (b/:bug_severity).first.innerHTML
        tags << "sev:#{severity}"
        
        # Status
        # new, open, resolved, hold, invalid
        # statuses: ["NEW", "ASSIGNED", "REOPENED", "RESOLVED", "VERIFIED", "CLOSED"]
        # resolutions: ["FIXED", "INVALID", "WONTFIX", "DUPLICATE", "WORKSFORME"]
        
        status      = (b/:bug_status).first.innerHTML.downcase
        resolution  = (b/:resolution).any? ? (b/:resolution).first.innerHTML.downcase : 'unresolved'
        
        state = 
          case status
          when 'new'
            'new'
          when 'assigned', 'reopened'
            'open'
          when 'resolved', 'verified', 'closed'
            'resolved'
          end
          
        case resolution
        when 'invalid', 'wontfix', 'duplicate', 'worksforme'
          state = 'invalid'
        end
        
        # Reporter
        reporter    = (b/:reporter).first.innerHTML
        reporter_id = @user_map[reporter]
        
        # Assignee
        assignee    = (b/:assigned_to).first.innerHTML
        assignee_id = @user_map[assignee]
        
        # Title
        title = CGI.unescapeHTML((b/:short_desc).innerHTML).gsub("&apos;", "'")
        
        # Description/Comments
        description = CGI.unescapeHTML(self.format_comments(b)).gsub("&apos;", "'")
        
        # Build the ticket
        ticket = Lighthouse::Ticket.new(:title             => title, 
                                        :body              => description,
                                        :assigned_user_id  => assignee_id,
                                        :creator_id        => reporter_id,
                                        :milestone_id      => milestone.id,
                                        :state             => state
                                        )
        ticket.prefix_options[:project_id] = @project.id
        ticket.tags += tags
        
        if ticket.save
          puts "Saved ticket #{ticket.id}"
        else
          puts "Unable to import ticket!"
        end
      end
    end
    
    def self.init
      Utilities.init
      
      @config = YAML.load_file('config.yml')
      
      @project = Utilities.get_project(CONFIG['project_name'])
      
      @doc = Hpricot.XML(File.read(@config['file']))
      @bugs = (@doc/:bug).sort_by {|b| (b/:bug_id).innerHTML.to_i}
      
      @user_map = { 
         "cmount@onehub.com"     => 17764, 
         "lcaplan@onehub.com"    => 16401, 
         "bcaplan@onehub.com"    => 34520, 
         "loe@onehub.com"        => 15047, 
         "lmoudy@onehub.com"     => 17762, 
         "mtierney@onehub.com"   => 34522, 
         "manderson@onehub.com"  => 16400, 
         "bmoran@onehub.com"     => 17763,
         }
      
      @user_map.default = 17763
    end
    
    def self.format_comments(bug)
      long_desc    = bug/:long_desc
    
      long_desc.map do |desc|
        time = Time.parse((desc/:bug_when).innerHTML).strftime("%m/%d/%Y @ %I:%M%p") rescue nil
        desc_array  = []
        desc_array << "#{(desc/:who).innerHTML} (#{time}) said:\n"
        desc_array << "#{(desc/:thetext).innerHTML}"
        desc_array.join("\n")
      end.join("\n\n#{'-' * 50}\n")      
    end
  end
end