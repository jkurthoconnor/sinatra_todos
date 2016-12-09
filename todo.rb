require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'

  set :erb, :escape_html => true
end


helpers do
  def completed?(list)
    (total_todos(list) > 0) && (todos_remaining(list) == 0)
  end

  def list_class(list)
    completed?(list) ? "complete" : ""
  end

  def item_class(item)
    item[:completed] == true ? "complete" : ""
  end

  def todos_remaining(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def total_todos(list)
    list[:todos].size
  end

  def sort_lists(lists, &block)
    sorted = lists.sort_by { |list| completed?(list) ? 1 : 0 }
    sorted.each do |list|
      yield(list)
    end
  end

  def sort_todos(todos, &block)
    sorted = todos.sort_by { |todo| todo[:completed] ? 1 : 0 }
    sorted.each do |todo|
      yield(todo)
    end
  end
end


before do
  session[:lists] ||= []
end


get "/" do
  redirect "/lists"
end


# view list of lists
get "/lists" do
  @lists = session[:lists]

  erb :lists, layout: :layout
end


# render new list form;
get "/lists/new" do
  erb :new_list, layout: :layout
end


def validate_and_load_list(id)
  if session[:lists].map { |list| list[:id] }.include?(id)
    session[:lists].find { |list| list[:id] == id }
  else
    session[:error] = "Requested list with id #{id} was not found."
    redirect "/lists"
  end
end

# show single list;
get "/lists/:id" do
  @list_id = params[:id].to_i
  @list = validate_and_load_list(@list_id)
  @todo_items = @list[:todos]

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


def next_list_id(lists)
  max = lists.map { |list| list[:id] }.max || 0
  max + 1
end


# create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_list_id(session[:lists])
    session[:lists] << {id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created!"
    redirect "/lists"
  end
end


#render edit list form
get "/lists/:id/edit" do
  @list = validate_and_load_list(params[:id].to_i)
  erb :edit_list, layout: :layout
end


#update list name
post "/lists/:id" do
  new_name = params[:new_name].strip
  @list = validate_and_load_list(params[:id].to_i)

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
  list = validate_and_load_list(params[:id].to_i)
  session[:lists].delete_if { |list| list[:id] == params[:id].to_i }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "'#{list[:name]}' has been deleted!"
    redirect "/lists"
  end
end


#validate new todo item
def error_for_todo(name)
  if !(1..100).cover?(name.size)
    "Todo item must be between 1 and 100 characters."
  elsif @todo_items.any? { |item| item[:name] == name }
    "Todo items must be unique."
  end
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end


# add a new todo item to a list
post "/lists/:id/todos" do
  @list_id = params[:id].to_i
  @list = validate_and_load_list(@list_id)
  @todo_items = @list[:todos]
  todo = params[:todo].strip

  error = error_for_todo(todo)

  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    id = next_todo_id(@todo_items)
    @todo_items << {id: id, name: todo, completed: false}
    session[:success] = "The todo has been added!"
    redirect "/lists/#{@list_id}"
  end
end


# delete a todo from a list
post "/lists/:id/todos/:item_id/delete" do
  @list_id = params[:id].to_i
  @list = validate_and_load_list(@list_id)
  id = params[:item_id].to_i
  @todo_items = @list[:todos]

  @todo_items.delete_if { |item| item[:id] == id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204 # ok no content
  else
    session[:success] = "Item deleted!"
    redirect "/lists/#{@list_id}"
  end
end


# update a todo's status
post "/lists/:id/todos/:item_id" do
  @list_id = params[:id].to_i
  @list = validate_and_load_list(@list_id)
  id = params[:item_id].to_i
  @todo_items = @list[:todos]

  is_it_complete = params[:completed] == 'true'
  item = @todo_items.select { |item| item[:id] == id}
  item[0][:completed] = is_it_complete
  session[:success] = "Item updated!"
  redirect "/lists/#{@list_id}"
end


# completes all items on list
post "/lists/:id/complete" do
  @list_id = params[:id].to_i
  @list = validate_and_load_list(@list_id)
  @todo_items = @list[:todos]

  @todo_items.each { |todo| todo[:completed] = true }
  session[:success] = "List completed!"
  redirect "/lists/#{@list_id}"
end