require 'rubyipmi/ipmitool/errorcodes'
require 'rubyipmi/observablehash'
require 'rubyipmi/commands/basecommand'
require 'rubyipmi/ipmitool/commands/basecommand'

Dir[File.dirname(__FILE__) + '/commands/*.rb'].each do |file|
  require file
end

module Rubyipmi
  module Ipmitool

    class Connection

      attr_accessor :options, :debug

      def initialize(user=nil, pass=nil, host=nil, opts={})
        @debug = opts[:debug]
        @options = Rubyipmi::ObservableHash.new
        if Rubyipmi.validate_host(host)
          unless host.nil?
            @options["H"] = host
          else
            opts[:driver] = 'open'
          end
        end
        # Credentials can also be stored in the freeipmi configuration file
        # So they are not required
        @options["U"] = user if user
        @options["P"] = pass if pass
        if opts.has_key?(:privilege)
          @options["L"] = opts[:privilege]
        end
        # Note: rubyipmi should auto detect which driver to use so its unnecessary to specify the driver unless
        #  the user really wants to.
        @options['I'] = drivers_map[opts[:driver]] unless drivers_map[opts[:driver]].nil?
      end

      def drivers_map
        {
          'lan15' => 'lan',
          'lan20' => 'lanplus',
          'open'  => 'open'
        }
      end

      def fru
        @fru ||= Rubyipmi::Ipmitool::Fru.new(@options)
      end

      def provider
        'ipmitool'
      end

      def bmc
        @bmc ||= Rubyipmi::Ipmitool::Bmc.new(@options)
      end

      def sensors
        @sensors ||= Rubyipmi::Ipmitool::Sensors.new(@options)
      end

      def chassis
        @chassis ||= Rubyipmi::Ipmitool::Chassis.new(@options)
      end

      def get_diag
        data = {}
        data['provider'] = provider
        if @fru
          data['frus'] = @fru.getfrus
        end
        if @sensors
          data['sensors'] = @sensors.getsensors
        end
        if @bmc
          data['bmc_info'] = @bmc.info
        end
      end
    end
  end
end
