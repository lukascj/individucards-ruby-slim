require_relative "../model.rb"
require "fileutils"
require "date"
require "json"

DB_PATH = "./cards.db"

# Raderar db-fil
def deleteDb(backup) 
  # Kollar att databasen finns innan den raderas
  if !File.exist?(DB_PATH)
    raise StandardError, "DB file doesn't exist."
  end
  
  # Om det ska skapas en backup, annars radera bara
  if backup
    last_slash_index = DB_PATH.rindex(".") || 0 # Index av sista snedstreck, 0 om inte finns
    last_dot_index = DB_PATH.rindex(".") || DB_PATH.length-1 # Index av sista punkt, sista tecknet i strängen om inte finns
    if last_slash_index < last_dot_index
      file_name = DB_PATH[(last_slash_index + 1)...last_dot_index]
      new_path = "#{DB_PATH[0...last_slash_index]}backups/#{substring}-#{Time.now.strftime("%Y-%m-%d")}.db"
      FileUtils.mv(DB_PATH, new_path)
      puts "Backup: #{new_path}"
    else
      raise StandardError, "Backup error."
    end
  else
    File.delete(DB_PATH)
    puts "File deleted."
  end

  return
end

# Skapar db-fil och applicerar schema
def createDb()
  # Ser till att databasen inte finns innan den skapas
  if File.exist?(DB_PATH) 
    raise StandardError, "DB file exists already."
  end

  # Applicerar schema från schema.sql
  db = SQLite3::Database.new(DB_PATH)
  puts "File created."
  query = File.read(File.join(__dir__, "schema.sql"))
  db.execute_batch(query)
  puts "Tables created."

  db.close
  return
end

def seedDb()
  # Kollar att databasen finns innan den seedas
  if !File.exist?(DB_PATH) 
    raise StandardError, "DB file doesn't exist."
  end

  db = SQLite3::Database.new(DB_PATH)

  # Stoppa in admin användare
  pwd_digest = BCrypt::Password.create("Str0ngPwd")
  query = <<-SQL
    INSERT INTO users (name, pwd, admin) 
    VALUES (?, ?, ?);
  SQL
  db.execute(query, ['admin', pwd_digest, 1])

  # Stoppa in default sets
  sets = JSON.parse(File.read(File.join(__dir__, "default_sets.json")))
  puts "Default sets data: \"#{sets}\"."
  query = ""
  values = []
  # Skapar SQL-query utefter JSON-data
  sets.each do |set|
    query += <<-SQL
      INSERT INTO sets (id, name)
      VALUES (?, ?); 
    SQL
    values.concat([set['id'], set['name']])

    set['people'].each do |person|
      query += <<-SQL
        INSERT INTO people (name, gender, img_url, set_id)
        VALUES (?, ?, ?, ?); 
      SQL
      values.concat([person['name'], person['gender'], person['img_url'], set['id']])
    end

    set['herrings'].each do |herring|
      query += <<-SQL
        INSERT INTO herrings (name, gender, set_id)
        VALUES (?, ?, ?); 
      SQL
      values.concat([herring['name'], herring['gender'], set['id']])
    end
  end

  puts "Running query: \"#{query}\"."
  puts "Values: \"#{values}\"."
  db.execute_batch(query, values)
  puts "Sets created."

  return
end

def run(backup = false)
  deleteDb(backup)
  createDb()
  seedDb()
end

run()