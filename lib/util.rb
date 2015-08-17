require 'yaml'
require 'fileutils'

module DockerMgr

  module Util

    def root_dir 
      return @root_dir if @root_dir
      error_message = "not within project tree"
      curr_dir = Dir.pwd
      return curr_dir if curr_dir.end_with? "/docker"
      dir_parts = curr_dir.split "/docker/"
      raise error_message if dir_parts == 1
      possible_root = "#{dir_parts[0]}/docker"
      raise error_message unless (Dir.entries(possible_root) && %w{admin backup apps}).length == 3
      @root_dir = possible_root
    end


    def backup_dir
      "#{root_dir}/backup" 
    end

    def base_images_dir
      "#{root_dir}/base_images"
    end


    def attic_dir
      "#{root_dir}/attic"
    end

    def apps_dir
      "#{root_dir}/apps"
    end

    def admin_dir
      "#{root_dir}/admin"
    end

    def routine_dir
      "#{admin_dir}/routines"
    end

    def install_dir
      "#{admin_dir}/installation_scripts"
    end

    def extract_date(entry)
      /_\d+\./.match(entry).to_s.chop[1..-1].to_i
    end

    def service_hooks_for(app_name,type)
      Dir.entries("#{apps_dir}/#{app_name}/administration/hooks/#{type}.d")
      .select {| entry | !entry.start_with?(".") && entry != "before_all" && entry != "after_all" }
    end

    def services(app_name)
      YAML.load(File.read("#{apps_dir}/#{app_name}/docker-compose.yml"))
      .each_key
      .select {|k| !k.end_with?("data")}
    end

    def data_services(app_name)
      YAML.load(File.read("#{apps_dir}/#{app_name}/docker-compose.yml")).each_key
      .select {|k| k.end_with?("data")}
    end

    def volumes(app_name,service_name)
      raw_volumes = YAML.load(File.read("#{apps_dir}/#{app_name}/docker-compose.yml"))["#{service_name}"]['volumes']
      raw_volumes.map do |volume|
        volume.chop! if volume.end_with? '/'
        volume[0] = '' if volume.start_with? '/'
        volume
      end
    end

    def exec_hook(app_name,type,hook_name)
      if File.exist? "#{apps_dir}/#{app_name}/administration/hooks/#{type}.d/#{hook_name}"
        `#{apps_dir}/#{app_name}/administration/hooks/#{type}.d/#{hook_name}`
      end
    end


    def remove_line_from_routine(routine,filter_line)
      File.open "#{routine_dir}/tmp","w" do | output_file |
        File.foreach "#{routine_dir}/#{routine}" do | line |
        output_file.write line unless line  == "#{filter_line}\n"
      end
      end
      FileUtils.mv "#{routine_dir}/tmp", "#{routine_dir}/#{routine}"
    end

    def add_line_to_routine(routine,line)
      File.open("#{routine_dir}/#{routine}",'a') { | file  | file.write("#{line}\n") }
    end


    def extract_git_variable(name)
      config = `git config --list`
      result = config.lines.grep(/#{Regexp.quote(name)}/).map{|e| e.split('=')[1].chomp }.first
      unless result
        puts "please enter your #{name.split('.')[1]}"
        result = STDIN.gets.chomp
        `git config --global #{name} #{result}`
      end
      result
    end

    def extract_email
      extract_git_variable("user.email")
    end

    def extract_name
      extract_git_variable("user.name")
    end

  end
end
