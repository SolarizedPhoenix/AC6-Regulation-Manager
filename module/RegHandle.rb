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
