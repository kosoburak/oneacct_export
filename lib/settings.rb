require 'settingslogic'

class Settings < Settingslogic
  CONF_NAME = "conf.yml"

  source "#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}" if File.exist?("#{ENV['HOME']}/.oneacct-export/#{CONF_NAME}")
  source "/etc/oneacct-export/#{CONF_NAME}" if File.exist?("/etc/oneacct-export/#{CONF_NAME}")
  source "config/#{CONF_NAME}"

end