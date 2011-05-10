class StagePrivilegesExtensionsGenerator < Rails::Generator::Base
  
  def manifest
    #added files
    record do |m|
	m.migration_template 'stage_privileges.rb', 'db/migrate', :migration_file_name => "stage_privileges"
	#models
	#13
	m.template 'stages_user.rb','app/models/stages_user.rb'
	#stage
	#12
	m.gsub_file 'app/models/stage.rb', /(#{Regexp.escape("class Stage < ActiveRecord::Base")})/mi do |match|
	"#{match}\n    
	has_many :stages_user\n
	has_many :users , :through => :stages_user\n"
	end

	m.gsub_file 'app/models/user.rb', /(#{Regexp.escape("has_and_belongs_to_many :projects")})/mi do |match|
	"#{match}\n    
	has_many :stages_user\n
	has_many :stages , :through => :stages_user\n
	def read_only(stage)\n
  		su = stages_user.find_by_stage_id(stage.id)\n
		return su.read_only? if su\n
		return false\n
  	end\n
	def access(stage)\n
		(stages_user.find_by_stage_id(stage.id).read_only?)? 'read only' : 'full access'\n
	end\n
	def project_stages(project)\n
		return stages if !stages\n
	  	stages.select{|stage| stage.project.id == project.id}\n
	end\n"
	end

	m.gsub_file 'app/controllers/project_users_controller.rb', /(#{Regexp.escape("@project.users.delete @project_user if @project.user_ids.include?(@project_user.id)")})/mi do |match|
		"#{match}\n    
	   	@project.stages.each do |stage|\n
	    		stage.users.delete @project_user if stage.user_ids.include?(@project_user.id)\n
	    	end\n"
	end

	#8
	m.template 'stage_users_controller.rb','app/controllers/stage_users_controller.rb'
	#deployments_controller
	#1
	m.gsub_file 'app/controllers/deployments_controller.rb', /(#{Regexp.escape("before_filter :load_stage")})/mi do |match|
	"#{match}\n  before_filter :ensure_user_access, :except => [:show, :latest, :index]\n"
	end
	#2
	m.gsub_file 'app/controllers/deployments_controller.rb', /(#{Regexp.escape("protected")})/mi do |match|
		"#{match}\n
		def ensure_user_access\n
			if (current_user.stages.include?( @stage) && !current_user.read_only(@stage)) || ensure_admin\n
				return true\n
			else\n
				flash[:notice] = \"Action not allowed\"\n
				return false\n
	    		end\n
		end\n"
	end
      
      #projects_controller
      #4
      m.gsub_file 'app/controllers/projects_controller.rb', /(#{Regexp.escape("class ProjectsController < ApplicationController")})/mi do |match|
        "#{match}\n  before_filter :ensure_user, :only => [:show]\n"
      end
      #5
	m.gsub_file 'app/controllers/projects_controller.rb', /(#{Regexp.escape("protected")})/mi do |match|
	"#{match}\n
	        def ensure_user\n
	    		if  current_user.projects.include?( Project.find(params[:id])) || ensure_admin\n
	    			return true\n
	    		else\n
	      			flash[:notice] = \"Action not allowed\"\n
	      			return false\n
	    		end\n
		end\n"
	end
	#roles_controller
	#6
	m.gsub_file 'app/controllers/roles_controller.rb', /(#{Regexp.escape("protected")})/mi do |match|
		"#{match}\n
		def ensure_user_access\n
			if (current_user.stages.include?(@stage) && !current_user.read_only(@stage)) || ensure_admin\n 
			return true\n
			else\n
					flash[:notice] = \"Action not allowed\"\n
					return false\n
			end\n
		end\n"
	end
  	#stage_configurations_controller
  	#7
	m.gsub_file 'app/controllers/stage_configurations_controller.rb', /(#{Regexp.escape("protected")})/mi do |match|
		"#{match}\n
		def ensure_user_access\n
		    	if (current_user.stages.include?( @stage) && !current_user.read_only(@stage)) || ensure_admin\n 
		    		return true\n
		    	else\n     	
		      		flash[:notice] = \"Action not allowed\"\n
		      	return false\n
		    	end\n
	  	end\n"
  	end
    
	#stages_controller
	#9
	m.gsub_file 'app/controllers/stages_controller.rb', /(#{Regexp.escape("before_filter :load_project")})/mi do |match|
		"#{match}\n    
		before_filter :ensure_user, :only => [:show]\n
		before_filter :ensure_user_access, :only => [:edit, :update, :destroy, :capfile, :recipes]\n"
	end
    
	#10
	m.gsub_file 'app/controllers/stages_controller.rb', /(#{Regexp.escape("def recipes")})/mi do |match|
	"\n    
	def ensure_user\n
		if current_user.stages.include?( Stage.find(params[:id])) || ensure_admin\n 
			return true\n
		else\n     	
			flash[:notice] = \"Action not allowed\"\n
			return false\n
		end\n
	end\n
	def ensure_user_access\n
		@stage = Stage.find(params[:id])\n
		if (current_user.stages.include?(@stage) && !current_user.read_only(@stage)) || ensure_admin\n 
			return true\n
		else\n     	
				flash[:notice] = \"Action not allowed\"\n
				return false\n
		end\n
	end\n
	#{match}"
	end
	        
	#routes.rb
	#19
	m.gsub_file 'config/routes.rb', /(#{Regexp.escape("stages.resources :stage_configurations")})/mi do |match|
		"\nstages.resources :stage_users\n#{match}"
	end

	m.gsub_file 'config/routes.rb', /(#{Regexp.escape("stages.resources :stage_configurations")})/mi do |match|
		"\nstages.resources :stage_users\n#{match}"
	end

	#15
	m.template 'views/_projects.html.erb', 'app/views/layouts/_projects.html.erb'

	#16
	m.template 'views/_users.html.erb', 'app/views/stages/_users.html.erb'

	#17
	m.template 'views/show.html.erb', 'app/views/stages/show.html.erb'
      
    end
  end
  
end
