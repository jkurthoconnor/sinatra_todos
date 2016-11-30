require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

not_found do
  redirect "/lists"
end

# view list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip
  if (1..100).cover?(list_name.size)
    session[:lists] << {name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    # session.keys => ["session_id", "csrf", "tracking", "lists", "success"]
    redirect "/lists"
  else
    session[:error] = "List name must be between 1 and 100 characters."
    erb :new_list, layout: :layout
  end
end


