require 'yaml'
require 'fileutils'
require 'pathname'

module DockerMgr

  module Util

    def root_dir 
      return @root_dir if @root_dir
      search_dir = Dir.pwd
      while search_dir && !root_dir_condition(search_dir)
        parent = File.dirname(search_dir)
        # project_root wird entweder der Root-pfad oder false. Wenn es false
        # wird, bricht die Schleife ab. Vgl. Rails
        search_dir = (parent != search_dir) && parent
      end
      project_root = search_dir if root_dir_condition(search_dir)
      raise 'you are not within a presentation-project.' unless project_root
      @root_dir = Pathname.new(File.realpath project_root)
    end

    def root_dir_condition(search_dir)
      search_dir.is_a?(String) && search_dir.end_with?("/docker") && (Dir.entries(search_dir) && %w{admin backup apps}).length == 3
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

    def proxy_dir
      "#{root_dir}/proxy"
    end



    def cert_dir
      "#{proxy_dir}/ca_certs"
    end

    def vhost_dir
      "#{proxy_dir}/vhosts.d"
    end

    def config 
      if File.exist? "#{admin_dir}/config.yml"
        YAML.load_file "#{admin_dir}/config.yml"
      else
        result = Hash.new
        result[:email] = extract_email
        result[:name] = extract_name
        host = "#{result[:name].gsub(/\s/,'-').downcase}.de"
        puts "pleas enter your host-name (#{host})"
        choice = STDIN.gets.chomp
        result[:host] = choice.empty? ? host : choice
        File.write "#{admin_dir}/config.yml", result.to_yaml
        result
      end
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
      git_config = `git config --list`
      result = git_config.lines.grep(/#{Regexp.quote(name)}/).map{|e| e.split('=')[1].chomp }.first
      unless result
        puts "please enter your #{name.split('.')[1]}"
        result = STDIN.gets.chomp
      end
      result
    end

    def extract_email
      extract_git_variable("user.email")
    end

    def extract_name
      extract_git_variable("user.name")
    end

    def generate_ca_installer
      directory "install_certificate","#{root_dir}/install_certificate"
      FileUtils.cp "#{admin_dir}/ca/rootCA.crt","install_certificate"
      package_tar "install_certificate"
      FileUtils.rm_rf "install_certificate"
    end

    def package_tar(dir_name,current_dir = nil)
      if current_dir
        `tar -cf #{dir_name}.tar -C #{current_dir} #{dir_name}` 
      else
        `tar -cf #{dir_name}.tar #{dir_name}` 
      end
    end



  end
end
