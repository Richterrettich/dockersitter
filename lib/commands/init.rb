require "thor/group"

class Init < Thor::Group
  include Thor::Actions
    
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
    empty_directory "docker/proxy/ca_certs"
    empty_directory "docker/proxy/vhosts.d"
    puts `git init docker`
  end

end
