  system("cls")

puts "Loading required gems..."

require 'digest'
require 'json'
require 'open-uri'
require 'zip'
require 'net/http'
require 'openssl'
#require './module/RegHandle.rb'

class RegHandle
  def backup(ac_dir)
    Dir.mkdir("#{Dir.home}/Documents/AC6-RM/Regulations/Pure")
    FileUtils.cp("#{ac_dir}/Game/regulation.bin", "#{Dir.home}/Documents/AC6-RM/Regulations/Pure/regulation.bin")
    data = {name:"Pure", description:"The Vanilla Regulation."}
    File.write("#{Dir.home}/Documents/AC6-RM/Regulations/Pure/regulation.json", JSON.generate(data))
    clean_temp
  end

  def ver_backup(ac_dir)
    puts "Grabbing Regulation @ #{ac_dir}..."
    FileUtils.cp("#{ac_dir}/Game/regulation.bin", "#{Dir.home}/Documents/AC6-RM/Temporary/regulation.bin")
    puts "Initializing Witchy to grab version data..."
    puts "-----"
    system("#{Dir.home}/Documents/AC6-RM/WitchyBND/WitchyBND.exe #{Dir.home}/Documents/AC6-RM/Temporary/regulation.bin")
    puts "-----"
    verdata = File.readlines("#{Dir.home}/Documents/AC6-RM/Temporary/regulation-bin/_witchy-bnd4.xml")[5].tr('^0-9', '')
    data = {name:"Pure #{verdata}", description:"The Vanilla Regulation. Version #{verdata}."}
    puts "Registering Regulation..."
    begin
      Dir.mkdir("#{Dir.home}/Documents/AC6-RM/Regulations/Pure-#{verdata}")
    rescue Errno::EEXIST
    end
    FileUtils.cp("#{Dir.home}/Documents/AC6-RM/Temporary/regulation.bin", "#{Dir.home}/Documents/AC6-RM/Regulations/Pure-#{verdata}/regulation.bin")
    File.write("#{Dir.home}/Documents/AC6-RM/Regulations/Pure-#{verdata}/regulation.json", JSON.generate(data))
    puts "Regulation Registered."
    clean_temp
  end

  def clean_temp
    FileUtils.rm_rf("#{Dir.home}/Documents/AC6-RM/Temporary/.", secure: true)
    Dir.mkdir("#{Dir.home}/Documents/AC6-RM/Temporary")
    puts "Temporary files cleaned."
  end
end


@reghandle = RegHandle.new


def check_settings()
  puts "Checking for settings file"
  if Dir.exist?("#{Dir.home}/Documents/AC6-RM") == false
    puts "AC6-RM Directory missing. Creating..."
    Dir.mkdir("#{Dir.home}/Documents/AC6-RM")
  end
  if File.exist?("#{Dir.home}/Documents/AC6-RM/settings.json") == false
    puts "Missing settings file. Creating..."
    tempsett = {pure:false, first_time:true}
    File.write("#{Dir.home}/Documents/AC6-RM/settings.json", JSON.generate(tempsett))
  end
  @settings = JSON.parse(File.read("#{Dir.home}/Documents/AC6-RM/settings.json"))
  if Dir.exist?("#{Dir.home}/Documents/AC6-RM/Regulations") == false
    puts "Regulation Directory missing. Creating..."
    Dir.mkdir("#{Dir.home}/Documents/AC6-RM/Regulations")
  end
  if Dir.exist?("#{Dir.home}/Documents/AC6-RM/Temporary") == false
    puts "Temporary Directory missing. Creating..."
    Dir.mkdir("#{Dir.home}/Documents/AC6-RM/Temporary")
  end
end

def save()
  File.write("#{Dir.home}/Documents/AC6-RM/settings.json", JSON.generate(@settings))
end

check_settings()

if @settings["first_time"]
  puts ">>>>>"
  puts "First time/missing settings detected."
  puts "This dialogue is to make sure a vanilla regulation is saved for future use,"
  puts "as well as specify a few settings."
  puts "-----"
  loop do
    puts "Where is your AC6 folder? If you do not wish to type it out, drag and drop"
    puts "the folder here."
    print ":> "
    location = gets.chomp
    puts "Verifying location..."
    location = location.split("\\").join("/").tr('"', '')
    if File.exist?("#{location}/Game/armoredcore6.exe")
      if File.exist?("#{location}/Game/regulation.bin")
        puts "Location verified."
        @settings["bin_location"] = location
        break
      else
        puts "regulation.bin is missing from this folder. This is not the correct folder."
      end
    else
      puts "armoredcore6.exe is missing from this folder. This is not the correct folder."
    end

  end
  loop do
    puts "Do you want AC6-RM to automatically detect updated regulations and save them as different"
    puts "pure versions?"
    print "y/n:> "
    acheck = gets.chomp
    if acheck.downcase == "n"
      @settings["behaviour"] = 0
      break
    elsif acheck.downcase == "y"
      puts "This requires a tool called WitchyBND."
      puts "https://github.com/ividyon/WitchyBND"
      loop do
        puts "Do you want me to set it up, or cancel?"
        puts "[1] Auto"
        puts "[2] Cancel"
        print ":> "
        optn = gets.chomp
        if optn == "1"
          puts "Grabbing release..."
          #https://github.com/ividyon/WitchyBND/releases/download/v2.0.1.0/WitchyBND-v2.0.1.0.zip
          File.open("#{Dir.home}/Documents/AC6-RM/WitchyBND.zip", "wb") do |saved_file|
            # the following "open" is provided by open-uri
            puts "I may seem frozen, I'm not! Just wait."
            URI.open("http://github.com/ividyon/WitchyBND/releases/download/v2.0.1.0/WitchyBND-v2.0.1.0.zip", {ssl_verify_mode: 0}) do |read_file|
              saved_file.write(read_file.read)
            end
          end
          puts "Release downloaded."
          puts "Unpacking..."
          Dir.mkdir("#{Dir.home}/Documents/AC6-RM/WitchyBND")
          Zip::File.open("#{Dir.home}/Documents/AC6-RM/WitchyBND.zip") do |file|
            file.each do |f|
              f_path = File.join("#{Dir.home}/Documents/AC6-RM/WitchyBND", f.name)
              puts "Extracting #{f.name}"
              FileUtils.mkdir_p(File.dirname(f_path))
              file.extract(f, f_path) unless File.exist?(f_path)
            end
          end
          puts "Setup complete."
          @settings["behaviour"] = 1
          break
        elsif optn == "2"
          puts "Cancelling."
          @settings["behaviour"] = 0
          break
        end
      end
      break
    end
  end

  loop do
    puts "Is your current regulation.bin pure? (unmodded)"
    print "y/n:> "
    pure = gets.chomp
    if pure.downcase == "y"
      puts "Creating automatic pure backup"
      if @settings["behaviour"] == 1
        @reghandle.ver_backup(@settings["bin_location"])
        break
      else
        @reghandle.backup(@settings["bin_location"])
        break
      end
    else
      puts "Unable to save pure backup. Continuing anyway, please make sure to back"
      puts "it up yourself at some point"
      break
    end
  end

  @settings["first_time"] = false
  File.write("#{Dir.home}/Documents/AC6-RM/settings.json", JSON.generate(@settings))

end

if @settings["behaviour"] == 1
  puts "Checking for new version..."
  puts "-----"
  FileUtils.cp("#{@settings["bin_location"]}/Game/regulation.bin", "#{Dir.home}/Documents/AC6-RM/Temporary/regulation.bin")
  system("#{Dir.home}/Documents/AC6-RM/WitchyBND/WitchyBND.exe #{Dir.home}/Documents/AC6-RM/Temporary/regulation.bin")
  verdata = File.readlines("#{Dir.home}/Documents/AC6-RM/Temporary/regulation-bin/_witchy-bnd4.xml")[5].tr('^0-9', '')
  if Dir.exist?("#{Dir.home}/Documents/AC6-RM/Regulations/Pure-#{verdata}") == false
    @reghandle.clean_temp
    loop do
      puts "New Regulation found! Are you currently running a modded regulation?"
      print "y/n:> "
      inp = gets.chomp.downcase
      if inp == "n"
        @reghandle.ver_backup(@settings["bin_location"])
        break
      elsif inp == "y"
        puts "Do you want to register it, or ignore for now?"
        puts "[1] Register"
        puts "[2] Ignore"
        print":> "
        inp = gets.chomp
        if inp == "1"
          puts "What do you want to call this Regulation?"
          print ":> "
          name = gets.chomp
          puts "What description should be saved with the Regulation?"
          print ":> "
          desc = gets.chomp
          puts "Importing..."
          Dir.mkdir("./Regulations/#{name}")
          FileUtils.cp(regfile, "./Regulations/#{name}/regulation.bin")
          File.write("./Regulations/#{name}/regulation.json", JSON.generate({name:name, description:desc}))
          break
        else
          puts "Ignoring..."
          break
        end
      end
    end
  else
    @reghandle.clean_temp
  end
end




loop do
  Dir.chdir("#{Dir.home}/Documents/AC6-RM/")
  system("cls")
  puts "     \\      ___|   /      _ \\    \\  | \n    _ \\    |       _ \\   |   |  |\\/ | \n   ___ \\   |      (   |  __ <   |   | \n _/    _\\ \\____| \\___/  _| \\_\\ _|  _| \n                                      "
  puts "    AC6 Regulation Manager V1.0.2"
  puts "[1] Install a Regulation"
  puts "[2] Import Regulation into AC6RM"
  puts "[0] Exit"
  print ":> "
  optin = gets.chomp
  if optin == "1"
    loop do
      Dir.chdir("./Regulations/")
      dirs = Dir.glob('*').select {|f| File.directory? f}
      dirs.each_with_index do |loc, inx|
        puts "[#{inx+1}] #{loc}"
      end
      puts "[0] Exit"
      print ":> "
      reg = gets.chomp.to_i - 1
      if reg == -1
        Dir.chdir("..")
        break
      end
      reginfo = JSON.parse(File.read("#{dirs[reg]}/regulation.json"))
      puts "Regulation Name: #{reginfo["name"]}"
      puts "  "
      puts reginfo["description"]
      puts "-----"
      puts "Install this Regulation?"
      print "y/n:>"
      deci = gets.chomp.downcase
      if deci == "y"
        File.delete("#{@settings["bin_location"]}/Game/regulation.bin")
        FileUtils.cp("./#{dirs[reg]}/regulation.bin", "#{@settings["bin_location"]}/Game/regulation.bin")
        puts "Regulation Installed."
        gets.chomp
        Dir.chdir("..")
        break
      end
    end
  elsif optin == "2"
    puts "Drag and drop the regulation.bin on this window, then press enter"
    location = gets.chomp
    regfile = location.split("\\").join("/").tr('"', '')
    puts "What do you want to call this Regulation?"
    print ":> "
    name = gets.chomp
    puts "What description should be saved with the Regulation?"
    print ":> "
    desc = gets.chomp
    puts "Importing..."
    Dir.mkdir("./Regulations/#{name}")
    FileUtils.cp(regfile, "./Regulations/#{name}/regulation.bin")
    File.write("./Regulations/#{name}/regulation.json", JSON.generate({name:name, description:desc}))
  elsif optin == "0"
    exit()
  end
end
