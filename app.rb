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
get('/') { redirect('/login')}

# Visar inloggningsformuläret när användaren besöker /login
get('/login') do
    slim(:login)
end

# Hanterar POST-förfrågning från inloggningsformuläret
post('/login') do
    # (Koden för att hantera inloggning verkar saknas här)
end

# Visar registreringsformuläret när användaren besöker /register
get('/register') do 
    slim(:register)
end

# Hanterar POST-förfrågning från registreringsformuläret
post('/register') do
    if session[:loggedIn]
        session.delete("loggedIn")
    end
    
    username = params[:username]
    password = params[:password]
    
    status, userId = createUser(username, password)    
    
    
    if status == 200
        session[:loggedIn] = userId
        redirect('/game')
    end
    
    redirect('/error')
    
    
    # Visar en felmeddelandesida när användaren besöker /error
    get('/error') do
        slim(:error)
    end
end
    