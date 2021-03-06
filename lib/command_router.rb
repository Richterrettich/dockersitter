require "commands/init"
require 'thor'
require 'commands/create'
require 'commands/delete'
require 'commands/generate'
require 'commands/backup_app.rb'
require 'commands/restore_app.rb'
require 'commands/start.rb'
require 'commands/increment.rb'
require 'util'
require 'fileutils'

module CommandRouter
  class Main < Thor
    include DockerMgr::Util

    register(Init, 'init', 'init', 'initializes a docker-project.')
    register(Create,'create','create','creates a new docker-unit.')
    register(Generate,'generate','generate','generates scripts')
    register(Delete,'delete','delete','deletes a docker-unit.')
    register BackupApp,'backup','backup','creates a backup of the given app.'
    register RestoreApp, 'restore','restore','restores an app.'
    register Start, 'start','start','starts one or multiple apps. If no apps are given, all apps will be started.'
    register Increment, 'increment','increment','increments the version of an image.'
  end
end
