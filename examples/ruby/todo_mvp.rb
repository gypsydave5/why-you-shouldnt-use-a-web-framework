# This example uses no routing library, and uses Rack's built in helpers to
# parse request and generate response
#
# This could probably be made better with some more ruby-ish love like (a)
# classes and (b) erb.
#
# Oh, and tests.

require 'rack'

# Wrap this up in a nicer API and a class - extend with a delete and edit
$todos = [{name: "Get up!", done: false}]

def add_todo name
  $todos.push({name: name, done: false})
end

def toggle_todo name
  $todos = $todos.map do |todo|
    if todo[:name] == name
      {name: name, done: !todo[:done]}
    else
      todo
    end
  end
end

# Here's a simple top level router

def new_router
  Proc.new do |env|
    request = Rack::Request.new(env)
    routes(request).finish
  end
end

def routes request
  puts "PATH: #{request.path}"
  case request.path
  when "/todo"
    todo_router request
  when "/new-todo"
    new_todo_router request
  when "/toggle-todo"
    toggle_todo_router request
  else
    not_found
  end
end

def toggle_todo_router request
  if request.get?
    return toggle_todo_handler request
  end

  invalid_method
end

def todo_router request
  if request.get?
    return show_todos_handler(request)
  end

  invalid_method
end

def new_todo_router request
  if request.get?
    return show_add_todo_form_handler request
  end

  if request.post?
    return add_todo_handler request
  end

  invalid_method
end

def show_add_todo_form_handler request
  response = Rack::Response.new
  response.status = 200
  response.set_header 'Content-Type', 'text/html'
  response.write page("Add new todo", new_todo_form())
  response
end

def add_todo_handler request
  name = request[:name]
  add_todo name
  redirect "/todo"
end

def show_todos_handler request
  response = Rack::Response.new
  response.status = 200
  response.set_header 'Content-Type', 'text/html'
  response.write page("Todos", link_to_add_new_todo, todo_list($todos))
  response
end

def toggle_todo_handler request
  puts request.params
  name = request[:name]
  toggle_todo name
  redirect "/todo"
end

def link_to_add_new_todo
  %|<a href="/new-todo">Add todo</a>|
end

def page title, *body
  %|<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>#{title}</title>
    <style>#{css}</style>
  </head>
  <body>
    <h1>TODOS</h1>
      #{body.join}
  </body>
</html>|
end

def todo_list todos
  "<ul>" + todos.map do |todo|
    name = todo[:name]
    completed_class = todo[:done] ? "complete" : "incomplete"
    icon = todo[:done] ? "(Undo)" : "Complete"
    url = "/toggle-todo?name=#{Rack::Utils.escape_path(name)}"

    %|<li class="todo-item">
    <span class="#{completed_class}">#{name}</span><a href="#{url}">#{icon}</a>
    </li>|
  end.join + "</ul>"
end

def new_todo_form
  %|<h2>Add a new todo item</h2>
  <form method="post">
  <input type="text" name="name" placeholder="e.g. Pick up shopping">
  <input type="submit" value="Add">
  </form>|
end

def css
  %|
  span.complete {
    text-decoration: line-through
  }
|
end

def not_found
  response = Rack::Response.new
  response.status = 404
  response
end

def invalid_method
  response = Rack::Response.new
  response.status = 405
  response
end

def redirect url
  response = Rack::Response.new
  response.redirect(url)
  response
end

Rack::Handler::WEBrick.run new_router, Port: 4545