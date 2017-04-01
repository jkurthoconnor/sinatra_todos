require 'sequel'

DB = Sequel.connect(adapter: 'postgres', database: 'todos')

# API for todos to interact via sequel library with psql database
class SequelPersistence
  def initialize(logger)
    DB.logger = logger
  end

  def find_list(list_id)
    all_lists.where(lists__id: list_id).first
  end

  def all_lists
    DB[:lists].left_join(:todos, list_id: :id).
      select_all(:lists).
      select_append do
        [count(todos__id).as(total_todos),
         count(nullif(todos__completed, true)).as(todos_remaining)]
      end.
      group(:lists__id).
      order(:lists__name)
  end

  def create_list(list_name)
    DB[:lists].insert(name: list_name)
  end

  def delete_list(id)
    DB[:todos].where(list_id: id).delete
    DB[:lists].where(id: id).delete
  end

  def update_list_name(list_id, name)
    DB[:lists].where(id: list_id).update(name: name)
  end

  def add_todo(list_id, todo_name)
    DB[:todos].insert(name: todo_name, list_id: list_id)
  end

  def delete_todo(todo_id)
    DB[:todos].where(id: todo_id).delete
  end

  def update_todo(todo_id)
    current_status = DB[:todos].where(id: todo_id).first[:completed]
    DB[:todos].where(id: todo_id).update(completed: !current_status)
  end

  def complete_all(list_id)
    DB[:todos].where(list_id: list_id).update(completed: true)
  end

  def find_todos_for_list(id)
    DB[:todos].where(list_id: id)
  end
end
