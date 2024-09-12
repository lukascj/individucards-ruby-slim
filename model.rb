require 'sinatra'
require 'bcrypt'
require 'sqlite3'
require 'json'

DB_PATH = "./db/cards.db"
PORT = "4568"

# Koppla till databasen
def dbConn()
    if !File.exist?(DB_PATH) 
        raise StandardError, "DB file doesn't exist."
    end

    db = SQLite3::Database.new(DB_PATH)
    db.results_as_hash = true
    return db
end

# Kolla om användaren finns i databasen
def fetchUserByUsername(username)
    db = dbConn()
    query = <<-SQL
        SELECT users.*, 
            (SELECT score FROM scores WHERE user_id = users.id ORDER BY scores.score DESC) AS highscore 
        FROM users 
        WHERE name = ?
    SQL
    user = db.execute(query, username).first || nil
    db.close
    return user
end

def createUser(username, pwd, pwd_re)

    username = username.lowercase
    result = {}

    # Validering av givna värden
    if username.empty? || pwd.empty? || pwd_re.empty?
        result[:error] = "Please fill in all fields."
        return result
    end
    if pwd != pwd_re
        result[:error] = "Confirmation password is incorrect."
        return result
    end
    if !!fetchUserByUsername(username)
        result[:error] = "This username is taken."
        return result
    end

    db = dbConn()
    pwd_digest = BCrypt::Password.create(pwd)
    query = "INSERT INTO users (name, pwd, admin) VALUES (?, ?, ?);"
    db.execute(query, [username, pwd_digest, 0])

    result[:user] = fetchUserByUsername(username)

    db.close
    return result
end

def loginUser(username, pwd)

    result = {}

    # Validering av givna värden
    if username.empty? || pwd.empty?
        result[:error] = "Please fill in all fields."
        return result
    end

    user = fetchUserByUsername(username)

    if !user
        result[:error] = "Wrong username or password."
        return result
    end
    if BCrypt::Password.new(user["pwd"]) != pwd
        result[:error] = "Wrong username or password."
        return result
    end

    result[:user] = user

    return result
end

# Get the 5 highest scores, limited to one per user
def fetchLeaderboardData(set_id = 1)
    db = dbConn()
    query = <<-SQL 
        SELECT DISTINCT users.name AS username, scores.score, scores.date 
        FROM scores INNER JOIN users ON users.id = scores.user_id
        WHERE scores.set_id = ?
        ORDER BY scores.score DESC
        LIMIT 10
    SQL
    leaderboard_data = db.execute(query, set_id)
    db.close
    return leaderboard_data
end

# Get all people-cards from set, return array of cards with id, name, gender, img_url
def fetchCardsData(set_id = 1)
    db = dbConn()
    query = <<-SQL
        SELECT *
        FROM people
        UNION
        SELECT *, NULL AS img_url
        FROM herrings
        WHERE set_id = ?
        ORDER BY RANDOM()
    SQL
    cards_data = db.execute(query, set_id)
    db.close
    return cards_data
end

def fetchUserRanking(username, set_id = 1)
    db = dbConn()
    query = <<-SQL
        SELECT DISTINCT users.name, 
            ROW_NUMBER() OVER (ORDER BY scores.score DESC) AS ranking 
        FROM scores 
        INNER JOIN users ON users.id = scores.user_id
        WHERE users.name = ? 
          AND scores.set_id = ?
        ORDER BY scores.score DESC
    SQL
    user = db.execute(query, [username, set_id]).first
    db.close
    return user
end