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

# render new list form; must be before /lists/:id route or it is called instead, raising a no method [] error when initializing @list_name
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

# show single list; must be after /lists/new route to not be matched/called in its place
get "/lists/:id" do
  @list_number = params[:id].to_i
  @list_name = session[:lists][@list_number][:name] # no method [] for nil; there are no lists at session[:lists] for [list_number] to retrieve by index;

  erb :single_list, layout: :layout
end

#render edit list form
get "/lists/:id/edit" do
  @list = session[:lists][params[:id].to_i]
  erb :edit_list, layout: :layout
end

#update list name
post "/lists/:id" do
  new_name = params[:new_name].strip
  @list = session[:lists][params[:id].to_i]

  error = error_for_list_name(new_name)

  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = new_name
    session[:success] = "The list has been updated!"
    redirect "/lists/:id"
  end
end




