require_relative "../model.rb"
require "fileutils"
require "date"

DB_PATH = "./cards.db"

# Raderar db-fil
def deleteDb(backup) 
  # Kollar att databasen finns innan den raderas
  if !File.exist?(DB_PATH)
    return {success: false, at: "deleteDb", msg: "DB file doesn't exist."} 
  end
  
  # File.delete eller FileUtils.mv kan kasta exceptions
  begin
    if backup
      last_slash_index = DB_PATH.rindex(".") || 0 # Index av sista snedstreck, 0 om inte finns
      last_dot_index = DB_PATH.rindex(".") || DB_PATH.length-1 # Index av sista punkt, sista tecknet i strängen om inte finns
      if last_slash_index < last_dot_index
        file_name = DB_PATH[(last_slash_index + 1)...last_dot_index]
        new_path = "#{DB_PATH[0...last_slash_index]}backups/#{substring}-#{Time.now.strftime("%Y-%m-%d")}.db"
        FileUtils.mv(DB_PATH, new_path)
        puts "Backup: #{new_path}"
      else
        return {success: false, at: "deleteDb", msg: "Backup error."}
      end
    else
      File.delete(DB_PATH)
      puts "File deleted."
    end
  rescue Errno::ENOENT => e
    # Hantera file-not-found problem
    puts "File not found: #{e.message}"
    return { success: false, at: "deleteDb", msg: "File not found: #{e.message}" }
  rescue Errno::EACCES => e
    # Hantera tillåtelse problem
    puts "Permission denied: #{e.message}"
    return { success: false, at: "deleteDb", msg: "Permission denied: #{e.message}" }
  rescue StandardError => e
    # Hantera andra potentiella problem
    puts "An error occurred: #{e.message}"
    return { success: false, at: "deleteDb", msg: "An error occurred: #{e.message}" }
  end

  return {success: true, at: "deleteDb"}
end

# Skapar db-fil och applicerar schema
def createDb()
  # Ser till att databasen inte finns innan den skapas
  if File.exist?(DB_PATH) 
    return {success: false, at: "createDb", msg: "DB file exists already."} 
  end

  # Fångar upp om koden kastar en exception
  # Exempelvis om databasen inte skapas eller om schemat inte appliceras ordentligt
  begin
    # Applicerar schema från schema.sql
    db = SQLite3::Database.new(DB_PATH)
    queries = File.read(File.join(__dir__, "schema.sql"))
    db.execute(queries)
  rescue SQLite3::SQLException => e
    # Hantera SQL-exceptions
    return {success: false, at: "createDb", msg: "An SQL error occurred: #{e.message}"} 
  rescue StandardError => e
    # Hantera övriga exceptions
    return {success: false, at: "createDb", msg: "An error occurred: #{e.message}"} 
  ensure
    # Se till att db-kopplingen stängs
    if db
      db.close
    end
  end

  db.close
  return {success: true, at: "createDb"}
end

def seedDb()
  # Kollar att databasen finns innan den seedas
  if !File.exist?(DB_PATH) 
    return {success: false, at: "seedDb", msg: "DB file missing."} 
  end



  return {success: true, at: "seedDb"}
end

def run(backup = false)
  delete_result = deleteDb(backup)
  if delete_result.success 
    create_result = createDb()
    if create_result.success
      seed_result = seedDb()
    end
  end
end

run()