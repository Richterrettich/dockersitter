require 'thor/group'
require 'fileutils'

class Increment < Thor::Group
  include Thor::Actions
  include DockerMgr::Util

  def self.source_root
    File.expand_path('../templates',__dir__)
  end


  class_option :minor,:aliases => 'm'
  argument :image_name,:type => :string

  def increment
    last_version_dir = Dir.entries("#{base_images_dir}/#{@image_name}")
                          .select {|e| e != "." && e != ".."}
                          .max {|a,b| a[1..-1].to_f <=> b[1..-1].to_f}
    last_number =  last_version_dir[1..-1].to_f

    new_number = options[:minor] ? last_number + 0.1 : last_number.to_i + 1.0
    new_number_format = '%.1f' % new_number
    empty_directory "#{base_images_dir}/#{@image_name}/v#{new_number_format}"
    FileUtils.cp_r "#{base_images_dir}/#{@image_name}/#{last_version_dir}/.",
                   "#{base_images_dir}/#{@image_name}/v#{new_number_format}"

    if File.exist? "#{base_images_dir}/#{@image_name}/v#{new_number_format}/build.sh"
      FileUtils.rm "#{base_images_dir}/#{@image_name}/v#{new_number_format}/build.sh"
    end
    @version = new_number_format
    template 'build.erb',"#{base_images_dir}/#{@image_name}/v#{new_number_format}/build.sh"
    FileUtils.chmod 0755, "#{base_images_dir}/#{@image_name}/v#{new_number_format}/build.sh"


  end

end
