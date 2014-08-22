require "oneacct_exporter/version"
require 'opennebula'
require 'one_worker'

class OneacctExporter
  CONVERT_FORMAT = "%014d"

  def initialize(options, log)
    @log = log
    @site_name = options.site_name
    @cloud_type = options.cloud_type
    @endpoint = options.endpoint
    @output = options.output
    @template = options.template_filename

    @range = {}
    @range[:from] = options.records_from
    @range[:to] = options.records_to

    @groups = {}
    if options.include_groups
      @groups[:include] = options.include_groups
    end
    if options.exclude_groups
      @groups[:exclude] = options.exclude_groups
    end

    if options.groups_file
      @log.debug("Reading groups from file...")
      unless File.exists?(options.groups_file) or File.readable?(options.groups_file)
        @log.error("File contaning groups: #{options.groups_file} doesn't exists or cannot be read. Skipping groups restriction...")
        @groups[@groups.keys.first] = []
      else
        file = File.open(options.groups_file, "r")
        file.each_line do |line|
          @groups[@groups.keys.first] << line
        end
        file.close
      end
    end
  end

  def export
    @log.debug("Starting export...")
    common_data = {}
    common_data["endpoint"] = @endpoint
    common_data["site_name"] = @site_name
    common_data["cloud_type"] = @cloud_type

    new_file_number = last_file_number + 1
    batch_number = 0
    oda = OneDataAccessor.new(@log)

    vms = []
    while vms = oda.vms(batch_number, @range, @groups)
      output_file = CONVERT_FORMAT % new_file_number
      @log.debug("Staring worker with batch number: #{batch_number}.")
      unless vms.empty?
        OneWorker.perform_async(common_data, vms.join("|"), @range, @groups, @template, "#{@output}/#{output_file}")
        new_file_number += 1
      end
      batch_number += 1
    end

    @log.debug("No more records. Exiting...")
  end

  def last_file_number
    output_dir = Dir.new(@output)
    last_file = output_dir.entries.sort.last
    /[0-9]{14}/ =~ last_file ? last_file.to_i : 0
  end
end