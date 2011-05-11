namespace :gknome do
  desc "Add a genome from <file>"
  task :genome, :file, :needs => :environment do |task, args|
    File.open(args[:file], "r") do |file|
      keys = file.readline.strip.split(/\t/)
      params = {}
      file.each_line do |line|
        values = line.strip.split(/\t/)
        values.each_index do |i|
          params[keys[i]] = values[i]
        end
        Genome.create(params)
      end
    end
  end
end