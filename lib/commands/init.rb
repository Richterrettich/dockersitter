require "thor/group"
require 'fileutils'
require 'util'

class Init < Thor::Group
  include Thor::Actions
  include DockerMgr::Util

  def self.source_root
    File.expand_path('../templates',__dir__)
  end

  def project_structure
    empty_directory "docker/apps"
    empty_directory "docker/attic"
    empty_directory "docker/backup"
    empty_directory "docker/base_images"
    directory "admin","docker/admin"
    empty_directory "docker/ci_runner"
    empty_directory "docker/proxy/certs"
    empty_directory "docker/proxy/vhosts.d"
    copy_file "gitignore","docker/.gitignore"
    FileUtils.cd 'docker/admin/ca' do 
      puts `openssl req -x509 -newkey rsa:4096 -keyout rootCA.key -out rootCA.crt -days 7800 -sha256`
    end
    chmod 'docker/admin/ca/rootCA.key',0600
    chmod 'docker/admin/ca/sign.sh',0755
    puts `git init docker`
    FileUtils.cd 'docker' do 
      generate_ca_installer
      image_name = 'base'
      @user_email,@user_name = config.values_at(:email,:name)
      image_path = "#{base_images_dir}/#{image_name}/v1.0"
      empty_directory "#{image_path}/administration/installation"
      @base = "ubuntu:14.04"
      template "Dockerfile.erb","#{image_path}/Dockerfile"
      %w(curl git).each do |package|
        FileUtils.cp("#{install_dir}/install_#{package}.sh", 
                     "#{image_path}/administration/installation/install_#{package}.sh")
      end

      FileUtils.cp("#{install_dir}/scriptrunner.sh", 
                   "#{image_path}/administration/scriptrunner.sh")
      FileUtils.cp("#{admin_dir}/trust.sh","#{image_path}/administration/trust.sh")
      FileUtils.mkdir("#{image_path}/administration/certificates")
      FileUtils.cp("#{admin_dir}/ca/rootCA.crt","#{image_path}/administration/certificates/rootCA.crt")
      @image_name = image_name
      @version = "1.0"
      template "build.erb", "#{image_path}/build.sh"
      FileUtils.chmod 0755, "#{image_path}/build.sh"
    end


  end
end
