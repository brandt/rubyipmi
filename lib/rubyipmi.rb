# Copyright (C) 2014 Corey Osman
#
#     This library is free software; you can redistribute it and/or
#     modify it under the terms of the GNU Lesser General Public
#     License as published by the Free Software Foundation; either
#     version 2.1 of the License, or (at your option) any later version.
#
#     This library is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     Lesser General Public License for more details.
#
#     You should have received a copy of the GNU Lesser General Public
#     License along with this library; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
#     USA
#


require 'rubyipmi/ipmitool/connection'
require 'rubyipmi/freeipmi/connection'


module Rubyipmi
  PRIV_TYPES = ['CALLBACK', 'USER', 'OPERATOR', 'ADMINISTRATOR']

  def self.valid_drivers
    ['auto', "lan15", "lan20", "open"]
  end

  def self.openipmi_available?
    value = File.exists?('/dev/ipmi0') || File.exists?('/dev/ipmi/0') || File.exists?('/dev/ipmidev/0')
  end

  # returns boolean true if privilege type is valid
  def self.supported_privilege_type?(type)
    PRIV_TYPES.include?(type)
  end

  # validate the privilege unless nil is specified
  def self.validate_privilege(privilege_type)
    if ! privilege_type.nil?
      privilege_type = privilege_type.upcase
      unless supported_privilege_type?(privilege_type)
        raise "Invalid privilege type :#{privilege_type}, must be one of: #{PRIV_TYPES.join("\n")}"
      end
    end
    true
  end

  #validate existence of host or validate openipmi is installed when nil
  def self.validate_host(host)
    if host.nil?
      raise 'No host was provided and openipmi is unavailable on this machine' unless openipmi_available?
    end
    true
  end

  def self.get_provider(provider)
    # use the first available provider
    case provider
      when 'any'
        if is_provider_installed?("freeipmi")
          provider = "freeipmi"
        elsif is_provider_installed?("ipmitool")
          provider = "ipmitool"
        else
          raise "No IPMI provider is installed, please install freeipmi or ipmitool"
        end
      when 'freeipmi','ipmitool'
        raise "The IPMI provider: #{provider} is not installed" unless is_provider_installed?(provider)
        provider
      else
        raise "Incorrect provider given, must use freeipmi or ipmitool"
    end
  end

  # The connect method will create a connection object based the provider type passed in
  # If provider is left blank the function will use the first available provider
  def self.connect(user=nil, pass=nil, host=nil, provider='any', opts={:driver => 'auto', :privilege  =>nil,
                                                           :timeout => 'default', :debug => false})

    # use this variable to reduce cmd calls
    installed = false

    if provider.is_a?(Hash)
      opts = provider
      provider = 'any'
    end

    # Verify options just in case user passed in a incomplete hash
    opts[:driver]  ||= 'auto'
    opts[:timeout] ||= 'default'
    opts[:debug]   = false if opts[:debug] != true

    validate_privilege(opts[:privilege])

    # Support multiple drivers
    # Note: these are just generic names of drivers that need to be specified for each provider
    unless valid_drivers.include?(opts[:driver])
      raise "You must specify a valid driver: #{valid_drivers.join(',')}"
    end

    # validate and get first installed provider
    provider = get_provider(provider)

    # If the provider is available create a connection object
    if provider == "freeipmi"
      @conn = Rubyipmi::Freeipmi::Connection.new(user, pass, host, opts)
    elsif provider == "ipmitool"
      @conn = Rubyipmi::Ipmitool::Connection.new(user,pass,host, opts)
    else
      raise "Incorrect provider given, must use freeipmi or ipmitool"
    end
  end

  def self.connection
    return @conn if @conn
    raise "No Connection available, please use the connect method"
  end

  # method used to find the command which also makes it easier to mock with
  def self.locate_command(commandname)
    location = `which #{commandname}`.strip
    if not $?.success?
      location = nil
    end
    return location
  end

  # Return true or false if the provider is available
  def self.is_provider_installed?(provider)
    case provider
      when "freeipmi"
        # since freeipmi is a suite of commands we can't just check for freeipmi command so we use ipmipower instead
        cmdpath = locate_command('ipmipower')
      when "ipmitool"
        cmdpath = locate_command('ipmitool')
      else
        raise "Invalid BMC provider type"
    end
    # return false if command was not found
    return ! cmdpath.nil?
  end

  def self.providers
    ["freeipmi", "ipmitool"]
  end

  # returns true if any of the providers are installed
  def self.provider_installed?
    providers_installed?.length > 0
  end

  def self.providers_installed?
    available = []
    providers.each do |prov|
      if is_provider_installed?(prov)
        available << prov
      end
    end
    return available
  end

  # gets data from the bmc device and puts in a hash for diagnostics
  def self.get_diag(user, pass, host)
    data = {}

    if Rubyipmi.is_provider_installed?('freeipmi')
      @freeconn = Rubyipmi::connect(user, pass, host, 'freeipmi')
      if @freeconn
        puts "Retrieving freeipmi data"
        data['freeipmi'] = @freeconn.get_diag
      end
    end
    if Rubyipmi.is_provider_installed?('ipmitool')
      @ipmiconn = Rubyipmi::connect(user, pass, host, 'ipmitool')
      if @ipmiconn
        puts "Retrieving ipmitool data"
        data['ipmitool'] = @ipmiconn.get_diag
      end
    end
    return data
  end

end
