require 'sinatra'
require 'bcrypt'
require 'sqlite3'
require 'json'

PORT = "4568"
IS_LOCAL = false
DB_PATH = "#{__dir__}/db/cards.db"

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

    username = username.downcase
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
    if BCrypt::Password.new(user['pwd']) != pwd
        result[:error] = "Wrong username or password."
        return result
    end

    result[:user] = user

    return result
end

# Hämta de 10 högsta poängen, begränsade till 1 per användare
def fetchLeaderboardData(set_id = 1)
    db = dbConn()
    query = <<-SQL
        WITH subquery AS (
            SELECT 
                id AS score_id,
                user_id,
                MAX(score) AS score, 
                date 
            FROM scores
            WHERE set_id = ?
            GROUP BY user_id
        )
        SELECT 
            subquery.score_id,
            users.id AS user_id,
            users.name AS username, 
            subquery.score,
            ROW_NUMBER() OVER (ORDER BY subquery.score DESC) AS ranking,
            subquery.date
        FROM users
        INNER JOIN subquery ON users.id = subquery.user_id
        ORDER BY subquery.score DESC
        LIMIT 10;
    SQL
    leaderboard_data = db.execute(query, set_id)
    db.close
    return leaderboard_data
end

# Hämta spel-data; people & herrings
def fetchGameData(set_id = 1)
    db = dbConn()
    
    name = "" 
    people = []
    herrings = []

    db.transaction do
        query = "SELECT name FROM sets WHERE id = ?"
        name = db.execute(query, set_id)

        query = <<-SQL
            SELECT * 
            FROM people
            WHERE set_id = ?
            ORDER BY RANDOM()
        SQL
        people = db.execute(query, set_id)

        query = <<-SQL
            SELECT * 
            FROM herrings
            WHERE set_id = ?
            ORDER BY RANDOM()
        SQL
        herrings = db.execute(query, set_id)
    end

    db.close
    return {id: set_id, name: name, people: people, herrings: herrings}
end

def fetchUserRanking(user_id, set_id = 1)
    db = dbConn()
    query = <<-SQL
        SELECT ROW_NUMBER() OVER (ORDER BY score DESC) AS ranking
        FROM scores 
        WHERE user_id = ? AND set_id = ?
        ORDER BY score DESC
        LIMIT 1
    SQL
    ranking = db.execute(query, [user_id, set_id]).first
    db.close
    return ranking.class == Hash ? ranking['ranking'] : nil
end

def sendScore(user_id, score, date, set_id = 1) 
    db = dbConn()
    query = <<-SQL
        INSERT INTO scores (user_id, score, date, set_id)
        VALUES (?, ?, ?, ?); 
    SQL
    db.execute(query, [user_id, score, date, set_id])
    db.close
    return
end

def fetchRecentPlay(user_id)
    db = dbConn()
    query = <<-SQL
        SELECT score, MAX(date) AS date, set_id
        FROM scores
        WHERE user_id = ?
    SQL
    recent_play = db.execute(query, user_id).first
    db.close
    return recent_play
end