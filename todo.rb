require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
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

# show single list
get "/lists/:number" do
  list_number = params[:number].to_i
  @list_name = session[:lists][list_number][:name]

  erb :single_list, layout: :layout
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# return an error message if name is invalid; return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List names must be unique."
  end
end

# create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    # session.keys => ["session_id", "csrf", "tracking", "lists", "success"]
    redirect "/lists"
  end
end


