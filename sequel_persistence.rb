require 'sequel'

# API for todos to interact via sequel library with psql database
class SequelPersistence
  def initialize(logger)
    @db = Sequel.connect(adapter: 'postgres', database: 'todos')
    @db.loggers << logger
  end

  def query(statement, *params)
    @logger.info "#{statement} : #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<~SQL
      SELECT lists.*,
      COUNT(NULLIF(todos.completed, TRUE)) AS todos_remaining,
      COUNT(todos.id) AS total_todos
      FROM lists
      LEFT OUTER JOIN todos ON lists.id=todos.list_id
      WHERE lists.id = $1
      GROUP BY lists.id
      ORDER BY lists.name;
    SQL

    result = query(sql, id)
 
    tuple_to_list_hash(result.first)
  end

  def all_lists
    @db[:lists].left_join(:todos, list_id: :id).
      select_all(:lists).
      select_append do
        [ count(todos__id).as(total_todos),
        count(nullif(todos__completed, true)).as(todos_remaining) ]
      end.
      group(:lists__id).
      order(:lists__name)
  end


  def create_list(list_name)
    sql = 'INSERT INTO lists (name) VALUES ($1);'
    query(sql, list_name)
  end

  def delete_list(id)
    todo_sql = 'DELETE FROM todos WHERE list_id=$1;'
    query(todo_sql, id)

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

  def find_todos_for_list(id)
    todo_sql = 'SELECT * FROM todos WHERE list_id = $1;'
    todo_result = query(todo_sql, id)
    todo_result.map do |todo_tuple|
      { id: todo_tuple['id'].to_i,
        name: todo_tuple['name'],
        completed: todo_tuple['completed'] == 't' }
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple['id'].to_i,
      name: tuple['name'],
      todos_remaining: tuple['todos_remaining'].to_i,
      total_todos: tuple['total_todos'].to_i }
  end
end
