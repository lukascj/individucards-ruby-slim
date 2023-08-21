# Kräver nödvändiga bibliotek och paket för programmet
require 'sinatra'
require 'slim'
require 'rerun'
require 'bcrypt'
require 'sqlite3'
require_relative './components/model.rb'

# Aktiverar sessioner för att lagra användarinformation mellan förfrågningar
enable :sessions
set :port, 3000

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

    status, userId = loginUser(username, password)

    if status == 200
        session[:loggedIn] = userId
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
    
    status, userId = createUser(username, password, passwordConfirm)    
    
    
    if status == 200
        session[:loggedIn] = userId
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
    slim(:start, locals: { sortedUsers: fetchSortedUsersbyHs() })
end

get('/game') do 
    slim(:game, locals: { cards: fetchCards() })
end