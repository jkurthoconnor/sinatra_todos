
require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: 'todos')
    @logger = logger
  end
  
  def query(statement, *params)
    @logger.info "#{statement} : #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = 'SELECT * FROM lists WHERE id = $1;'
    result = query(sql, id)

    tuple = result.first

    todos = find_todos_for_list(id)
    {id: tuple['id'].to_i, name: tuple['name'], todos: todos }
   end

  def all_lists
    sql = 'SELECT * FROM lists ;'
    result = query(sql)

    result.map do |tuple|
      todos = find_todos_for_list(tuple['id'].to_i)

      {id: tuple['id'].to_i, name: tuple['name'], todos: todos }
    end
      # session[:lists] structure: `[{:id=>"1", :name=>"homework", :todos=>[]}, {:id=>"2", :name=>"groceries", :todos=>[]}, {:id=>"3", :name=>"chores", :todos=>[]}]`
  end

  def create_list(list_name)
    # id = next_id(all_lists)
    # @session[:lists] << {id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    # @session[:lists].delete_if { |list| list[:id] == id }
  end

  def update_list_name(list_id, name)
    # list = find_list(list_id)
    # list[:name] = name
  end

  def add_todo(list_id, todo_name)
    # list = find_list(list_id)
    # id = next_id(list[:todos])
    # list[:todos] << {id: id, name: todo_name, completed: false}
  end

  def delete_todo(list_id, todo_id)
    # list = find_list(list_id)
    # list[:todos].delete_if { |item| item[:id] == todo_id }
  end

  def update_todo(list_id, todo_id)
    # list = find_list(list_id)
    # item = list[:todos].find { |todo| todo[:id] == todo_id }
    # item[:completed] = !item[:completed]
  end

  def complete_all(list_id)
    # list = find_list(list_id)
    # list[:todos].each { |todo| todo[:completed] = true }
  end

  private

  def find_todos_for_list(id)
    todo_sql = 'SELECT * FROM todos WHERE list_id = $1;'
    todo_result = query(todo_sql, id)
    todo_result.map do |todo_tuple|
      {id: todo_tuple['id'].to_i, # nb: values returned by pg are strings
       name: todo_tuple['name'],
       completed: todo_tuple['completed'] == 't'} # converts to boolean
    end
  end
end