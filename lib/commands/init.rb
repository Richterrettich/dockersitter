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
      puts FileUtils.pwd
      generate_ca_installer
    end
  end

end
