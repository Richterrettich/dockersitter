require 'util'
require 'fileutils'
require 'thor/group'

class Start < Thor::Group
  include DockerMgr::Util

  argument :app_name,
    :required => false

  def start
    if @app_name
      start_app(@app_name)
    else
      Dir.entries(apps_dir)
         .select{|e| e != '.' && e != '..'} 
         .each(&method(:start_app))
    end
  end

  no_tasks do 
    def start_app(app_name)
      app_path = "#{apps_dir}/#{app_name}"
      FileUtils.cd app_path do
        puts `docker-compose up -d`
      end
    end
  end
end

