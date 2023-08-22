# Kräver nödvändiga bibliotek och paket för programmet
require 'sinatra'
require 'slim'
require 'rerun'
require 'bcrypt'
require 'sqlite3'
require_relative './components/model.rb'

# Aktiverar sessioner för att lagra användarinformation mellan förfrågningar
key = SecureRandom.hex(32)
enable :sessions
set :session_secret, key
set :sessions, :expire_after => 2592000

before do
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

    # userRanking = sortedUsers.index { |user| user["username"] == your_username }

    slim(:start, locals: { sortedUsers: sortedUsers })
end

get('/game') do 
    cardsJSON, randCards = fetchCards()
    slim(:game, locals: { cardsJSON: cardsJSON, randCards: randCards })
end

post('/game') do
    request.body.rewind
    data = JSON.parse(request.body.read)
    score = data['score']
    
    p score
    redirect('/start')
  end