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

  class_option :image,
    :type => :string,
    :desc => "the image which the app is based on.",
    :alias => 'i',
    :default => "ubuntu:14.04"

  class_option :env,
    :type => :array,
    :desc => 'additional environment variables',
    :alias => 'e',
    :default => []

  class_option :packages,
    :type => :array,
    :desc => 'additional packages to install',
    :alias => 'p',
    :default => []

  class_option :volumes,
    :type => :array,
    :desc => 'the volumes your data-container will mount',
    :alias => 'v',
    :default => ["/var"]

  desc "app APP_NAME", "create a new app."
  option :dockerfile,
    :type => :boolean,
    :desc => 'create a dockerfile for the app',
    :aliases => 'd'
  def app(app_name)
    @app_name = app_name
    @user_email = extract_email
    @user_name = extract_name
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
  end
  
  desc "image IMAGE_NAME","creates a new image."
  def image(image_name)
    @user_email = extract_email
    @user_name = extract_name
    image_path = "#{base_images_dir}/#{image_name}"
    empty_directory "#{image_path}/administration/installation"
    template "Dockerfile.erb","#{image_path}/Dockerfile"
    unless options[:packages].empty?
      options[:packages].each do |package|
        FileUtils.ln("#{install_dir}/install_#{package}.sh", 
                     "#{image_path}/administration/installation/install_#{package}.sh")
      end

      FileUtils.ln("#{install_dir}/scriptrunner.sh", 
                   "#{image_path}/administration/scriptrunner.sh")
    end

  end
end
