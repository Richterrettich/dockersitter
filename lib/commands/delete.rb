require 'util'
require 'fileutils'

class Delete < Thor
  include Thor::Actions
  include DockerMgr::Util

  desc 'app APP_NAME','deletes an app'
  def app(app_name)
    @app_name = app_name
    abort "#{@app_name} is not a valid app" unless Dir.exist? "#{apps_dir}/#{@app_name}"
    choice = ask "do you want to remove #{@app_name}? (y,N)"
    abort "aborting" unless choice == 'y'
    FileUtils.cd "#{apps_dir}/#{@app_name}" do
      puts `docker-compose -f rm` 
    end
    puts `tar -zcf #{attic_dir}/#{@app_name}.tar -C #{apps_dir} #{@app_name}`
    FileUtils.rm_rf "#{apps_dir}/#{@app_name}"
    FileUtils.rm_rf "#{backup_dir}/#{@app_name}"
    remove_line_from_routine("backup_routine","docker_mgr backup_app #{@app_name}")
  end

end
