require 'optparse'
require 'fileutils'
require 'erb'
require_relative '../util'

class Create < Thor 
  include Thor::Actions
  include DockerMgr::Util

  def self.source_root
    File.expand_path('../templates',__dir__)
  end

  class_option :base,
    :type => :string,
    :desc => "the image which the app is based on.",
    :aliases => 'b',
    :default => "base:1.0"

  class_option :env,
    :type => :array,
    :desc => 'additional environment variables',
    :aliases => 'e',
    :default => []

  class_option :packages,
    :type => :array,
    :desc => 'additional packages to install',
    :aliases => 'p',
    :default => []

  
  desc "app APP_NAME", "create a new app."
  option :dockerfile,:type => :boolean,
	 :desc => 'create a dockerfile for the app',:aliases => 'd'
  option :volumes,:type => :array,
    	 :desc => 'the volumes your data-container will mount',:aliases => 'v',
    	 :default => ["/var"]
  option :cert,:desc => "creates a ssl certificate for this app",:aliases =>'c'
  option :subdomain,:desc => "the subdomain for this app",:type => :string
  def app(app_name)
    subdomain = options.fetch(subdomain,app_name.gsub(/\s/,"-").downcase)
    @domain = "#{subdomain}.#{config[:host]}"
    @app_name = app_name
    @user_email,@user_name = config.values_at(:email,:name)
    @base = options[:base]
    app_path = "#{apps_dir}/#{@app_name}"
    template "docker-compose.yml.erb","#{app_path}/docker-compose.yml"
    empty_directory "#{app_path}/administration/installation"
    empty_directory "#{app_path}/administration/hooks/backup.d"
    empty_directory "#{app_path}/administration/hooks/restore.d"

    template "Dockerfile.erb","#{app_path}/Dockerfile" if options[:dockerfile]
    unless options[:packages].empty?
      options[:packages].each do |package|
        FileUtils.ln("#{install_dir}/install_#{package}.sh", 
                     "#{app_path}/administration/installation/install_#{package}.sh")
      end

      FileUtils.ln("#{install_dir}/scriptrunner.sh", 
                   "#{app_path}/administration/scriptrunner.sh")
      
    end
    append_to_file "#{routine_dir}/backup_routine", "docker_mgr backup_app #{app_name}"
    create_file "#{vhost_dir}/#{@domain}"
    if options[:cert]
      FileUtils.cd "#{admin_dir}/ca" do
	      puts "#{admin_dir}/ca/sign.sh"
	      puts `./sign.sh #{@domain}`
      end
      chmod "#{proxy_dir}/certs/#{@domain}.key",0600
    end
  end
  
  desc "image IMAGE_NAME","creates a new image."
  def image(image_name)
    @user_email,@user_name = config.values_at(:email,:name)
    @base = options[:base]
    image_path = "#{base_images_dir}/#{image_name}/v1.0"
    empty_directory "#{image_path}/administration/installation"
    template "Dockerfile.erb","#{image_path}/Dockerfile"
    unless options[:packages].empty?
      options[:packages].each do |package|
        FileUtils.cp("#{install_dir}/install_#{package}.sh", 
                     "#{image_path}/administration/installation/install_#{package}.sh")
      end

      FileUtils.cp("#{install_dir}/scriptrunner.sh", 
                   "#{image_path}/administration/scriptrunner.sh")
      FileUtils.cp("#{admin_dir}/trust.sh", 
                   "#{image_path}/administration/trust.sh")
      empty_directory("#{image_path}/administration/certificates")
    end
    @image_name = image_name
    @version = "1.0"
    template "build.erb", "#{image_path}/build.sh"
    FileUtils.chmod 0755, "#{image_path}/build.sh"
  end
end
