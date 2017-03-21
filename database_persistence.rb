require 'pg'

# API for todos to interact with psql database
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
    { id: tuple['id'].to_i, name: tuple['name'], todos: todos }
  end

  def all_lists
    sql = 'SELECT * FROM lists ;'
    result = query(sql)

    result.map do |tuple|
      todos = find_todos_for_list(tuple['id'].to_i)

      { id: tuple['id'].to_i, name: tuple['name'], todos: todos }
    end
  end

  def create_list(list_name)
    sql = 'INSERT INTO lists (name) VALUES ($1);'
    query(sql, list_name)
  end

  def delete_list(id)
    sql = 'DELETE FROM lists WHERE id=$1;'
    query(sql, id)
  end

  def update_list_name(list_id, name)
    sql = 'UPDATE lists SET name=$1 WHERE id=$2;'
    query(sql, name, list_id)
  end

  def add_todo(list_id, todo_name)
    sql = 'INSERT INTO todos (name, list_id) VALUES ($1, $2);'
    query(sql, todo_name, list_id)
  end

  def delete_todo(todo_id)
    sql = 'DELETE FROM todos WHERE id=$1;'
    query(sql, todo_id)
  end

  def update_todo(todo_id)
    sql = 'UPDATE todos SET completed=NOT(SELECT completed FROM todos ' \
          'WHERE id=$1) WHERE id=$1;'
    query(sql, todo_id)
  end

  def complete_all(list_id)
    sql = 'UPDATE todos SET completed=TRUE WHERE list_id=$1;'
    query(sql, list_id)
  end

  private

  def find_todos_for_list(id)
    todo_sql = 'SELECT * FROM todos WHERE list_id = $1;'
    todo_result = query(todo_sql, id)
    todo_result.map do |todo_tuple|
      { id: todo_tuple['id'].to_i,
        name: todo_tuple['name'],
        completed: todo_tuple['completed'] == 't' }
    end
  end
end
