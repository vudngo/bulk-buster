require 'csv'
require 'json'

class Briefcase

  attr_accessor :start_time, :total_time, :filename

  def initialize(description, type="csv")
    @start_time = Time.now
    @current_time = Time.now
    @filename = "#{description}_output" + ".#{type}"
    @logfile = []
    @total_busted = 0
    @root_dir = Rails.root.to_s
  end

  def parse_input_file(filename)
    csv = CSV.new(File.open(@root_dir + "/public/uploads/" + filename).read, :headers => true, :header_converters => :symbol)
    file_hash = csv.to_a.map {|row| row.to_hash }
  end

  def parse_output_file(filename)
    begin
      csv = CSV.new(File.open(@root_dir + "/public/output/" + filename).read, :headers => true, :header_converters => :symbol)
      file_hash = csv.to_a.map {|row| row.to_hash }
    rescue
      return {}
    end
  end

  def log(campaign)
    this_time = Time.now - @current_time
    @logfile << campaign
    @total_busted += 1

    @current_time = Time.now
    puts "Campaign completed in: #{this_time.to_s}\n"

  end

  def save
    @total_time = @start_time - Time.now
    print "Writing output file..."

    CSV.open(Rails.root.join(OUTPUT_DIRECTORY, @filename), "wb") do |csv|
      csv << @logfile.first.keys
      @logfile.each do |hash|
        csv << hash.values
      end
    end

    print " done."

    puts "\n\nBusting Complete"
    puts "-----------------------------"
    puts "Total busted: #{@total_busted}"
    puts "Time Elapsed: " + (Time.now - @start_time).to_s
    puts "Average Time: " + ( (Time.now - @start_time) / @total_busted ).to_s
    puts "-----------------------------\n\n"

  end



end