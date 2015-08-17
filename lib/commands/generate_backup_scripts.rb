require 'fileutils'
require 'util'
require 'yaml'
require 'thor'
require 'thor/group'

class GenerateBackupScripts < Thor::Group
  include DockerMgr::Util
  include Thor::Actions

  def self.source_root
    File.expand_path('../templates',__dir__)
  end

  argument :app_name,
    :type => :string,
    :desc => 'name of the app'

  def generate_backup_scripts
    app_path = "#{apps_dir}/#{@app_name}"
    hooks = data_services(@app_name)
    hooks << "before_all"
    hooks << "after_all"
    %w(backup restore).each do | hook_type |
      hooks.each do | hook  |
        @service = hook
        template_name = hook == 'before_all' || hook == 'after_all' ? hook : hook_type
        template "#{template_name}.erb","#{app_path}/administration/hooks/#{hook_type}.d/#{hook}"
        FileUtils.chmod 0750,"#{app_path}/administration/hooks/#{hook_type}.d/#{hook}"
      end
    end
  end
end
