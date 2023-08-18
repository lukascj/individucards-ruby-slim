require 'sinatra'
require 'bcrypt'
require 'sqlite3'

#Connect to the database
def connectToDb()
    db = SQLite3::Database.new("db/new.db")
    db.results_as_hash = true
    return db
end

#Check if the user exists in the database
def getUserByUsername(username)
    db = connectToDb()
    user = db.execute("SELECT * FROM users WHERE username=?", username).first || nil
    return user
end

#create user with username and password, return status code 200 if user created, and userId
def createUser(username, password)
    status = 200
    db = connectToDb()
    user = getUserByUsername(username)

    if user 
        return status = 400
    end

    passwordDigest = BCrypt::Password.create(password)
    db.execute(
      "INSERT INTO users (username, passwordDigest) VALUES (?, ?);",
      [username.downcase, passwordDigest]
    )
    userId = user["id"]

    return status, userId 
end