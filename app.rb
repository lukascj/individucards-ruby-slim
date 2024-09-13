# Kräver nödvändiga bibliotek och paket för programmet
require "sinatra"
require "slim"
require "rerun"
require "bcrypt"
require "sqlite3"
require "json"

require_relative "./model.rb"

# Aktiverar sessioner för att lagra användarinformation mellan requests
enable :sessions
# Skapar en säker, slumpmässig nyckel
key = SecureRandom.hex(32) # 32 bytes slumpmässighet
set :session_secret, key
set :sessions, :expire_after => 2592000 # Loggar ut användaren efter 30 dagar

before do
  # För att undvika CORS problem
  response.headers["Access-Control-Allow-Origin"] = "http://localhost:#{PORT}"
  response.headers["Access-Control-Allow-Methods"] = "GET, POST"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type"

  # Om första besöket
  if session[:not_init].nil?
    session[:not_init] = true

    # Temporär
    # session[:local_version] = true
    # session[:leaderboard_data] = []

    session[:user] = {
      id: nil,
      name: nil,
      highscore: 0,
      recent_play: {},
      ranking: nil,
    }
  end

  # Omdiregerar användaren till inloggningssidan om hen inte är inloggad och inte använder den lokala versionen av sidan
  protected_routes = ["/", "/game"]
  if protected_routes.include?(request.path_info) && !session[:logged_in] && !session[:local_version]
    redirect("/auth")
  end
end

after do
  if request.path_info != "/logout" # Rensa inte errors vid logout för då visas de inte efter omdiregering
    if session[:error] != nil
      session[:error] = nil
    end
    if session[:success] != nil
      session[:success] = nil
    end
  end
end

get("/") do
  # Leaderboard datan ser olika ut beroende på om det är online-versionen eller inte
  # Online-versionen ger en plats per användare utefter highscore
  # Den lokala versionen visar upp de högsta poängen som fåtts, flera kan vara av samma spelare
  if !session[:local_version]
    # Om det inte är den lokala versionen
    leaderboard_data = fetchLeaderboardData() # Hash sorterad efter ranking
    if leaderboard_data.length > 0
      # Hämtar din ranking
      your_row = leaderboard_data.find{|row| row[:username] == session[:user][:name]}
      session[:user][:ranking] = your_row ? your_row[:ranking] : fetchUserRanking(session[:user][:name])
    else
      # Om tom leaderboard
      session[:user][:ranking] = 0
    end
  else
    leaderboard_data = session[:leaderboard_data]
    if leaderboard_data.length > 0
      # Hämtar din ranking
      session[:user][:ranking] = leaderboard_data.find{|row| row[:username] == session[:user][:name]}[:ranking]
    else
      # Om tom leaderboard
      session[:user][:ranking] = "N/A"
    end
  end

  # Highlighta rad från det senaste spelet (om finns)
  row_index = leaderboard_data.index{|row| row == session[:user][:recent_play]}
  if row_index != nil
    leaderboard_data[row_index][:highlighted] = true
  end

  puts "data: #{leaderboard_data}"
  puts "me: #{session[:user]}"

  locals = {
    user: session[:user],
    leaderboard_data: leaderboard_data, 
    error: session[:error],
    success: session[:success]
  }
  slim(:start, locals: locals)
end

# Visar inloggningsformuläret
get("/auth") do
  if session[:logged_in]
    session[:error] = "You're already logged in."
    redirect("/")
  end
  slim(:auth, locals: { error: session[:error] })
end

# Hanterar POST-request från inloggningsformuläret
post("/login") do
  # Validering
  if !params[:username] || !params[:pwd]
    session[:error] = "Parameters missing."
    redirect("/auth")
  end
  if session[:logged_in]
    session[:error] = "You're already logged in."
    redirect("/")
  end

  result = loginUser(params[:username], params[:pwd])

  if !result[:error]
    session[:logged_in] = true
    session[:user][:id] = result[:user]['id']
    session[:user][:name] = result[:user]['name']
    session[:user][:highscore] = result[:user]['highscore'] || 0
    session[:success] = "You have successfully logged in."
    redirect("/")
  end

  session[:error] = result[:error]
  redirect("/auth")
end

# Hanterar POST-request från registreringsformuläret
post("/register") do
  # Validering
  if !params[:username] || !params[:pwd] || !params[:pwd_re]
    session[:error] = "Parameters missing."
    redirect("/auth")
  end
  if session[:logged_in]
    session[:error] = "You're already logged in."
    redirect("/")
  end
  
  result = createUser(username, params[:pwd], params[:pwd_re])

  if !result[:error]
    session[:logged_in] = true
    session[:user][:id] = result[:user]['id']
    session[:user][:name] = result[:user]['name']
    session[:user][:highscore] = result[:user]['highscore'] || 0
    session[:success] = "You have successfully registered and logged in."
    redirect("/")
  end

  session[:error] = result[:error]
  redirect("/auth")
end

# Sidan där spelet sker
get("/game") do
  set_id = params[:set] || 1

  begin
    game_data = fetchGameData(set_id)
  rescue SQLite3::Exception => e
    # Omdiregera till huvudsida om hämtning av data strular
    puts "An error occurred: #{e.message}"
    session[:error] = "An error occurred: #{e.message}"
    redirect("/")
  end

  slim(:game, locals: { game_data: game_data.to_json })
end

# Hanterar spel-resultatet
post("/game") do
  # Tillåter request body att bli läst (read)
  request.body.rewind
  parsed_request = JSON.parse(request.body.read, symbolize_names: true)

  # Konvertera från strängar
  parsed_request[:score] = parsed_request[:score].to_f
  parsed_request[:set_id] = parsed_request[:set_id].to_i

  # Spara i session
  session[:user][:recent_play] = parsed_request
  
  # Skicka till databasen
  sendScore(session[:user][:id], parsed_request[:score], parsed_request[:date], parsed_request[:set_id]);
  
  if session[:user][:recent_play][:score] > session[:user][:highscore]
    # Uppdatera highscore om besegrat
    session[:user][:highscore] = session[:user][:recent_play][:score]
  end

  content_type :json
  { message: "Score received successfully.", received_score: parsed_request[:score], status: 200 }.to_json
end

# För utloggning
get("/logout") do
  session.delete("logged_in")
  redirect("/auth")
end
