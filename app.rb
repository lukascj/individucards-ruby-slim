# Kräver nödvändiga bibliotek och paket för programmet
require 'sinatra'
require 'slim'
require 'rerun'
require 'bcrypt'
require 'sqlite3'
require 'json'
require_relative './components/model.rb'

# Aktiverar sessioner för att lagra användarinformation mellan förfrågningar
key = SecureRandom.hex(32)
enable :sessions
set :session_secret, key
set :sessions, :expire_after => 2592000

before do
    response.headers['Access-Control-Allow-Origin'] = 'http://localhost:4567'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'

    protectedRoutes = ["/start", "/game"]
    if protectedRoutes.include?(request.path_info)
      if !session[:loggedIn]
        redirect("/auth")
      end
    end
end

# Om användaren besöker rotmappen, omdirigera dem till inloggningsidan
get('/') { redirect('/auth')}

# Visar inloggningsformuläret när användaren besöker /login
get('/auth') do
    slim(:auth)
end

# Hanterar POST-förfrågning från inloggningsformuläret
post('/login') do
    if session[:loggedIn]
        session.delete("loggedIn")
    end

    username = params[:username]
    password = params[:password]

    status, user = loginUser(username, password)

    if status == 200
        session[:loggedIn] = user
        redirect('/start')
    end

    redirect('/error')
end

# Hanterar POST-förfrågning från registreringsformuläret
post('/register') do
    if session[:loggedIn]
        session.delete("loggedIn")
    end
    
    username = params[:username]
    password = params[:password]
    passwordConfirm = params[:passwrodConfirm]
    
    status, user = createUser(username, password, passwordConfirm)    
    
    
    if status == 200
        session[:loggedIn] = user
        redirect('/start')
    end
    
    redirect('/error')
    
end

# Visar en felmeddelandesida när användaren besöker /error
get('/error') do
    slim(:error)
end

# start sida / leaderboard
get('/start') do
    sortedUsers = fetchSortedUsersbyHs()
    user = Hash.new

    userRanking = sortedUsers.index { |user| user["username"] == session[:loggedIn]["username"] }

    user["ranking"] = userRanking + 1

    user["highscore"] = session[:loggedIn]["highscore"]

    user["username"] = session[:loggedIn]["username"]

    current_score = session[:score] || 0

    p user

    slim(:start, locals: { sortedUsers: sortedUsers, current_score: current_score, user: user })
end

get('/game') do 
    cardsJSON, randCards = fetchCards()
    slim(:game, locals: { cardsJSON: cardsJSON, randCards: randCards })
end

post('/game') do
    request.body.rewind
    data = JSON.parse(request.body.read)
    score = data['score']
    
    session[:score] = score

    updateScore(score)  

    content_type :json
    { message: "Score received successfully", received_score: score, status: 200 }.to_json
  end