require 'fileutils'
require 'open3'
require 'thor/group'
require 'thor'


class RestoreApp < Thor::Group
  include Thor::Actions
  include DockerMgr::Util


  argument :app_name
  def restore
    
    app_backup_dir = "#{backup_dir}/#{app_name}"
    app_backup_tmp_dir = "#{app_backup_dir}/tmp"

    reverse_sorted_entries = Dir.entries(app_backup_dir)
    .select {|entry| entry != "." && entry != ".."}
    .sort {| a,b | extract_date(b) <=> extract_date(a)}

    puts "please select your backup"
    reverse_sorted_entries.each_with_index{|entry,i| puts "#{i+1} #{entry}"}
    puts "(a) abort"

    choice = STDIN.gets.chomp

    abort "aborting" unless %w(1 2 3).include? choice

    chosen_backup = reverse_sorted_entries[choice.to_i - 1]

    choice = yes?("do you want to restore the data-container back to #{Time.at(extract_date(chosen_backup).to_i).strftime '%d.%m.%Y-%H:%M:%S'} (y,N)")

    abort "aborting" unless choice

    puts `tar -zxf #{app_backup_dir}/#{chosen_backup} -C #{app_backup_dir}`

    FileUtils.cd "#{apps_dir}/#{@app_name}" do 
      puts 'executing before_all hook'
      puts exec_hook(@app_name,"restore","before_all")
      service_hooks_for(@app_name,"restore").each do |service|
        script_path = "#{apps_dir}/#{@app_name}/administration/hooks/restore.d/#{service}"
        puts "executing #{script_path}" 
        Open3.popen3("#{script_path} #{app_backup_tmp_dir}/#{service} 2>&1") do |i,o,e,th|
          while line = o.gets do 
            puts line
          end
        end
      end 
      puts 'executing after_all hook'
      puts exec_hook(@app_name,"restore","after_all")
    end

    `sudo rm -rf #{app_backup_tmp_dir}`
  end
end
