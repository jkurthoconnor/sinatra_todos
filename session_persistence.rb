
class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def find_list(id)
    @session[:lists].find { |list| list[:id] == id }
  end

  def all_lists
    @session[:lists]
  end

  def create_list(list_name)
    id = next_id(all_lists)
    @session[:lists] << {id: id, name: list_name, todos: [] }
  end

  def delete_list(id)
    @session[:lists].delete_if { |list| list[:id] == id }
  end

  def update_list_name(list_id, name)
    list = find_list(list_id)
    list[:name] = name
  end

  def add_todo(list_id, todo_name)
    list = find_list(list_id)
    id = next_id(list[:todos])
    list[:todos] << {id: id, name: todo_name, completed: false}
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].delete_if { |item| item[:id] == todo_id }
  end

  def update_todo(list_id, todo_id)
    list = find_list(list_id)
    item = list[:todos].find { |todo| todo[:id] == todo_id }
    item[:completed] = !item[:completed]
  end

  def complete_all(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end

  private

  def next_id(collections)
    max = collections.map { |list| list[:id] }.max || 0
    max + 1
  end
end