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
  end

  def create_ca
    FileUtils.cd 'docker/admin/ca' do 
      puts `openssl req -x509 -newkey rsa:4096 -keyout rootCA.key -out rootCA.crt -days 7800 -sha256`
    end
    chmod 'docker/admin/ca/rootCA.key',0600
    chmod 'docker/admin/ca/sign.sh',0755
    FileUtils.cd 'docker' do 
      generate_ca_installer
    end
  end

  def init_git
    puts `git init docker`
  end

  def create_base_image
    @user_email,@user_name = config.values_at(:email,:name)
    image_name = 'base'
    image_path = "#{base_images_dir}/#{image_name}/v1.0"
    @image_name = image_name
    @version = "1.0"
    @base = "ubuntu:14.04"
    create_image(image_path,'curl','git')
  end

  def create_base_runner
    @image_name = 'runner_base'
    image_path = "#{base_images_dir}/#{@image_name}/v1.0"
    @version = "1.0"
    @base = "ayufan/gitlab-ci-multi-runner:latest"
    create_image(image_path,'java','node','ruby','ruby_buildtools','node_buildtools')
  end

  no_tasks do
    def create_image(image_path,*packages)
      empty_directory "#{image_path}/administration/installation"
      template "Dockerfile.erb","#{image_path}/Dockerfile"
      add_packages(image_path,packages)
      FileUtils.cp("#{admin_dir}/trust.sh","#{image_path}/administration/trust.sh")
      FileUtils.mkdir("#{image_path}/administration/certificates")
      FileUtils.cp("#{admin_dir}/ca/rootCA.crt","#{image_path}/administration/certificates/rootCA.crt")
      template "build.erb", "#{image_path}/build.sh"
      FileUtils.chmod 0755, "#{image_path}/build.sh"
    end
  end
end
