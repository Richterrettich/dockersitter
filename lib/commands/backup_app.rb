require 'fileutils'
require 'open3'
require 'thor/group'


class BackupApp < Thor::Group
  include DockerMgr::Util

  argument :app_name


  def backup
    app_backup_dir = "#{backup_dir}/#{@app_name}"
    tmp_dir = "#{app_backup_dir}/tmp"

    FileUtils.mkdir_p app_backup_dir
    FileUtils.mkdir_p tmp_dir

    before_all = "#{apps_dir}/#{@app_name}/administration/hooks/backup.d/before_all"
    after_all = "#{apps_dir}/#{@app_name}/administration/hooks/backup.d/after_all"

    FileUtils.cd "#{apps_dir}/#{@app_name}" do 
      puts `#{before_all}` if File.exist? before_all
      service_hooks_for(@app_name,"backup").each do | service_name |
        FileUtils.mkdir_p "#{tmp_dir}/#{service_name}"
        puts "executing #{apps_dir}/#{@app_name}/administration/hooks/backup.d/#{service_name} #{tmp_dir}/#{service_name}"
        Open3.popen3("#{apps_dir}/#{@app_name}/administration/hooks/backup.d/#{service_name} #{tmp_dir}/#{service_name} 2>&1")  do  |i,o,e,th|
          while line=o.gets do 
            puts line
          end
        end
      end
      puts `#{after_all}` if File.exist? after_all
    end

    puts `tar czf #{app_backup_dir}/#{@app_name}_#{Time.now.to_i}.tar.gz --directory=#{app_backup_dir} tmp`

    FileUtils.rm_rf tmp_dir

    entries = Dir.entries("#{app_backup_dir}")
    .select { | entry | entry != "." && entry != ".." && entry.start_with?("#{@app_name}_") }
    .sort { | a,b | extract_date(b) <=> extract_date(a) }
    .drop(3)
    .each { | entry | FileUtils.rm "#{app_backup_dir}/#{entry}"}



  end


end
