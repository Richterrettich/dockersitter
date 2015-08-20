require 'fileutils'
require 'util'
require 'yaml'

class Generate < Thor
  include DockerMgr::Util
  include Thor::Actions

  def self.source_root
    File.expand_path('../templates',__dir__)
  end

  desc 'ca-installer','generates a new ca-installer package with root certificate and installation script.'
  def ca_installer 
    generate_ca_installer   
  end

  
  desc 'backup-scripts APP_NAME','generates the backup scripts for the given app.'
  def backup_scripts(app_name)
    @app_name = app_name
    app_path = "#{apps_dir}/#{@app_name}"
    hooks = data_services(@app_name)
    hooks << "before_all"
    hooks << "after_all"
    %w(backup restore).each do | hook_type |
      hooks.each do | hook |
        @service = hook
        template_name = hook == 'before_all' || hook == 'after_all' ? hook : hook_type
        template "#{template_name}.erb","#{app_path}/administration/hooks/#{hook_type}.d/#{hook}"
        FileUtils.chmod 0750,"#{app_path}/administration/hooks/#{hook_type}.d/#{hook}"
      end
    end
  end
end
