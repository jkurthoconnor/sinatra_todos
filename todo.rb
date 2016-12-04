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

# not_found do
#   redirect "/lists"
# end

# view list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end


# render new list form; must be before /lists/:id route or it is called instead, raising a no method [] error when initializing @list_name
get "/lists/new" do
  erb :new_list, layout: :layout
end


# show single list; 
# fix bug: currently must be after /lists/new route to not be matched/called in its place
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

  erb :single_list, layout: :layout
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
    redirect "/lists"
  end
end


# delete a list
post "/lists/:id/delete" do
  list = session[:lists][params[:id].to_i]
  session[:lists].delete_at(params[:id].to_i)
  session[:success] = "'#{list[:name]}' has been deleted!"
  redirect "/lists"
end


#validate new todo item
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo item must be between 1 and 100 characters."
  elsif @todo_items.any? { |item| item[:name] == name }
    "Todo items must be unique."
  end
end


# add a new todo item to a list
post "/lists/:id/todos" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  @todo_items = @list[:todos]
  todo = params[:todo].strip

  error = error_for_todo(todo)

  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    @todo_items << {name: todo, completed: false}
    session[:success] = "The todo has been added!"
    redirect "/lists/#{@list_id}"  #must interpolate from params[:id], as opposed to simply redirect to `/lists/:id` because `:id` in the route simply says 'collect everything here under the `:id` key in `params`
  end
end


# delete a todo from a list
post "/lists/:id/todos/:index/delete" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  index = params[:index].to_i

  @list[:todos].delete_at(index)
  session[:success] = "Item deleted!"
  redirect "/lists/#{@list_id}"
end
