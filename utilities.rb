require 'lighthouse'

module LighthouseImporter
  include Lighthouse
  
  class Utilities
    ACCOUNT = 'onehub'
    TOKEN   = '273220aacded80c4adad164fb347e31e56dde3d5'

    def self.delete_all_tickets(options = {})
      self.init
      project = get_project(options[:project_name])
      
      while (tickets = project.tickets(:q => 'all')).size > 0 do
        tickets.each do |ticket|
          if options[:ids]
            ticket.destroy if options[:ids].include?(ticket.id)
          else
            ticket.destroy
          end
          puts "deleted ticket #{ticket.id}"
        end
      end
      
      puts 'deleted!'
    end
    
    def self.get_project(name)
      projects = Lighthouse::Project.find(:all)
      project  = projects.find {|pr| pr.name == name}
    end
    
    protected
    
    def self.init
      Lighthouse.account = CONFIG['account']
      Lighthouse.token   = CONFIG['token']
    end
  end
end
