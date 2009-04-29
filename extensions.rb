module Lighthouse
  class Project
    def add_ticket(options={})
      milestone_id = options[:milestone] ? options.delete(:milestone).id : options[:milestone_id]
      Ticket.new(options.merge(:project_id => self.id, :milestone_id => milestone_id))
    end
    
    def find_or_create_milestone(options={})
      @cached_milestones ||= self.milestones
      unless milestone = @cached_milestones.find {|ms| ms.title == options[:title]}
        milestone = Lighthouse::Milestone.new(options)
        milestone.prefix_options[:project_id] = self.id
        milestone.save
        @cached_milestones << milestone
      end
      
      milestone
    end
  end
end