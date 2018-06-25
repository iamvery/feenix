# Let's Build a Phoenix!

When you get started with Elixir Phoenix, you'll often hear "it's just a function pipeline!" Okay! But when you look at an app, it doesn't really _look_ like it. Is it? If so, how? Let's dive it!

Here's an example of a basic Phoenix application:

```elixir
# endpoint.ex
defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, ...

  # various plugs
  plug(YourApp.Router)
end
```

```elixir
# router.ex
defmodule YourApp.Router do
  use Phoenix.Router
  ...

  get "/cats", YourApp.Controller, :index
  get "/cats/felix", YourApp.Controller, :show
  post "/cats", YourApp.Controller, :create
end
```

```elixir
# controller.ex
defmodule YourApp.Controller do
  use Phoenix.Controller, ...

  def index(conn, _params) do
    send_resp(conn, 200, "meows")
  end

  def show(conn, _params) do
    send_resp(conn, 200, "just meow")
  end

  def create(conn, %{"name" => name}) do
    send_resp(conn, 201, "created #{name}!")
  end
end
```

And with that basic application, you can send some requests:

```sh
$ curl http://localhost:4000/cats
meows
$ curl http://localhost:4000/cats/felix
just meow
$ curl -X POST 'http://localhost:4000/cats?name=Garfield'
created Garfield!
```

So where's the function pipeline? If you know anything about Plug, that's a strong hint. The whole idea behind Plug is creating function pipelines, _plugs_. If you're familiar with Ruby, you can sort of think of Plug as the Elixir equivalent of Ruby's Rack, which is itself a function pipeline.

You can sort of see how the router is _plugged_ into the endpoint, and it sort of seems to delegate to the controller for certain requests. But routers are very declarative. How does that work? In a word, metaprogramming. Phoenix uses Elixir's rich metaprogramming model to surface a simple DSL for _declaring_ routes so that you don't have to fool with the pattern-matching underpinnings of its implementation.

### The Endpoint

The entry point for a request in a Phoenix app is the _endpoint_. That's it, the first step. What purpose does an endpoint serve? Let me name them:

1. It sets up the Elixir web server to handle requests.
2. It preprocesses the request in various ways. Rubyists think: Rack middleware. This includes things like handling static assets, implementing HTTP method override, and logging requests. (take a peek at the generated endpoint.ex in your Phoenix projects)
3. It hands off (pipes) the request to your router!

Start simple, make your app's endpoint a pipeline using [`Plug.Builder`](https://hexdocs.pm/plug/Plug.Builder.html).

```elixir
# your_app/endpoint.ex
defmodule YourApp.Endpoint do
  use Plug.Builder

  plug(:hello)
  plug(:world)

  def hello(conn, _opts) do
    IO.puts("hello")
    conn
  end

  def world(conn, _opts) do
    IO.puts("world")
    conn
  end
end
```

Now you can pipe a connection through your endpoint!

```
iex(1)> YourApp.Endpoint.call(%Plug.Conn{}, nil)
hello
world
%Plug.Conn{...}
```

Cool! That sets up most of #2, but the endpoint still needs to handle the web requests that you wish to pipe _into_ it. Lucky you, Plug has a convenient adapter to Cowboy, a popular Erlang web server.

```diff
 # your_app/endpoint.ex
 defmodule YourApp.Endpoint do
+  def start_link do
+    options = []
+    Plug.Adapters.Cowboy2.http(__MODULE__, options)
+  end
+
   use Plug.Builder

   plug(:hello)
   plug(:world)

   def hello(conn, _opts) do
-    IO.puts("hello")
-    conn
+    put_private(conn, :name, "world")
   end

   def world(conn, _opts) do
-    IO.puts("world")
-    conn
+    send_resp(conn, 200, "hello #{conn.private.name}")
   end
 end
```

```diff
 # your_app.ex
 defmodule YourApp do
   use Application

   def start(_type, _args) do
     import Supervisor.Spec

     children = [
-      # supervisor(YourApp.Endpoint, []),
+      supervisor(YourApp.Endpoint, []),
     ]

     Supervisor.start_link(children, strategy: :one_for_one, name: YourApp.Supervisor)
   end
 end
```

Nice! Now you can start your application and send it actual requests 😍.

```sh
$ curl http://localhost:4000/does/not/matter/because/no/routing/is/implemented
hello world
```

You might have noticed that there is no output in the `iex` window. Our server doesn't produce any logs by default. This can be really helpful for debugging, and the solution is easy enough.

```diff
 # your_app/endpoint.ex
 defmodule YourApp.Endpoint do
   def start_link do
     options = []
     Plug.Adapters.Cowboy2.http(__MODULE__, options)
   end

   use Plug.Builder

+  plug(Plug.Logger)
   plug(:hello)
   plug(:world)

   def hello(conn, _opts) do
     put_private(conn, :name, "world")
   end

   def world(conn, _opts) do
     send_resp(conn, 200, "hello #{conn.private.name}")
   end
 end
```

Now you'll get a little feedback from your Elixir process.

```
16:43:17.800 [info]  GET /cats
16:43:17.800 [info]  Sent 200 in 19µs
```

That's about it for the endpoint, but as you can see from the request we sent our app, there is no concept of request path or routing happening. Enter the router...

### The Router

You have a web app! Pretty exciting, but chances are your app is more complicated than what can be done with a single function. You will want to be able to model different pages and resources using the request path. This is web app 101, and Phoenix solves this problem by _routing_ requests to different functions handy for constructing responses. That's the purpose of the Router. Receive a request, and based on its details like the HTTP verb and path, figure out which function should handle buliding a response.

Plug your router into your endpoint.

```diff
 # your_app/endpoint.ex
 defmodule YourApp.Endpoint do
   def start_link do
     options = []
     Plug.Adapters.Cowboy2.http(__MODULE__, options)
   end

   use Plug.Builder

-  plug(:hello)
-  plug(:world)
-
-  def hello(conn, _opts) do
-    put_private(conn, :name, "world")
-  end
-
-  def world(conn, _opts) do
-    send_resp(conn, 200, "hello #{conn.private.name}")
-  end
+  plug(YourApp.Router)
 end
```

Just like the endpoint, the router is a _function pipeline_ (seeing a theme?) Functions can be _plugged_ in router to handle shared concerns like authentication and content type negotiation.

Start by making your router a pipeline with `Plug.Builder` and define a few routes to _match_ on.

```elixir
# your_app/router.ex
defmodule YourApp.Router do
  use Plug.Builder
  plug(:match)

  def match(conn, _opts) do
    do_match(conn, conn.method, conn.path_info)
  end

  # get "/cats"
  def do_match(conn, "GET", ["cats"]) do
    send_resp(conn, 200, "meows")
  end

  # get "/cats/felix"
  def do_match(conn, "GET", ["cats", "felix"]) do
    send_resp(conn, 200, "just meow")
  end

  # post "/cats"
  def do_match(conn, "POST", ["cats"]) do
    send_resp(conn, 201, "meow!")
  end
end
```

Most of the "magic" comes from Plug. You can see that a `%Plug.Conn{}` has a `path_info` property. The value of this property is a data structure that plug parses the request path into. Pattern matching is a great fit for function dispatch!

Make some requests.

```sh
$ curl http://localhost:4000/cats
meows
$ curl http://localhost:4000/cats/felix
just meow
```

Looking good! But you probably recognize that this isn't looking much like a Phoenix application. For one, you never have to write your own matching functions like this. Phoenix provides a DSL. We'll get to that shortly, but for now let's talk about _controllers_.

### The Controller

It would be unwhieldy define the behavior of every route in the router. Controllers give you a mechanism of collecting related functions into modules as destinations for routed requests. Continue to iterate on you app by extracting response-building logic to a controller. Your router should call your controller.

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
   use Plug.Builder
   plug(:match)

   def match(conn, _opts) do
     do_match(conn, conn.method, conn.path_info)
   end

   # get "/cats"
   def do_match(conn, "GET", ["cats"]) do
-    send_resp(conn, 200, "meows")
+    YourApp.Controller.index(conn)
   end

   # get "/cats/felix"
   def do_match(conn, "GET", ["cats", "felix"]) do
-   send_resp(conn, 200, "just meow")
+    YourApp.Controller.show(conn)
   end

   # post "/cats"
   def do_match(conn, "POST", ["cats"]) do
-    send_resp(conn, 201, "meow!")
+    YourApp.Controller.create(conn)
   end
 end
```

And then define the controller actions.

```elixir
# your_app/controller.ex
defmodule YourApp.Controller do
  import Plug.Conn

  def index(conn) do
    send_resp(conn, 200, "meows")
  end

  def show(conn) do
    send_resp(conn, 200, "just meow")
  end

  def create(conn) do
    send_resp(conn, 201, "meow!")
  end
end
```

This is a good start, but there's an important piece missing. Controllers are also function pipelines, so we need to make our controller pluggable. This allows you do to things on the connection before your controller actions run.

To illustrate this problem, consider setting some data in a plug in your controller.

```diff
 # your_app/controller.ex
 defmodule YourApp.Controller do
   import Plug.Conn

+  plug(:assign_kitty_count)

   def index(conn) do
-    send_resp(conn, 200, "meows")
+    send_resp(conn, 200, "#{conn.assigns.count} meows")
   end

   def show(conn) do
     send_resp(conn, 200, "just meow")
   end

   def create(conn) do
     send_resp(conn, 201, "meow!")
   end
+
+  defp assign_kitty_count(conn, _opts) do
+    assign(conn, :count, 42)
+  end
 end
```

This fails immediately because the controller is not pluggable!

This isn't as simple as making the controller pluggable. Specific actions themselves are not plugs. They can't be, because you only want to run the _requested_ actions. To pull this off, you must generalize a way to determine which action was meant and apply that function dynamically with a plug.

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
   use Plug.Builder
   plug(:match)

   def match(conn, _opts) do
     do_match(conn, conn.method, conn.path_info)
   end

   # get "/cats"
   def do_match(conn, "GET", ["cats"]) do
-    YourApp.Controller.index(conn)
+    YourApp.Controller.call(conn, :index)
   end

   # get "/cats/felix"
   def do_match(conn, "GET", ["cats", "felix"]) do
-    YourApp.Controller.show(conn)
+    YourApp.Controller.call(conn, :show)
   end

   # post "/cats"
   def do_match(conn, "POST", ["cats"]) do
-    YourApp.Controller.create(conn)
+    YourApp.Controller.call(conn, :create)
   end
 end
```

```diff
 # your_app/controller.ex
 defmodule YourApp.Controller do
-  import Plug.Conn
-
+  use Plug.Builder
+
+  def call(conn, action) do
+    conn
+    |> put_private(:action, action)
+    |> super(nil)
+  end
+
   plug(:assign_kitty_count)
+  plug(:apply_action)
+
+  def apply_action(conn, _opts) do
+    apply(__MODULE__, conn.private.action, [conn])
+  end

   def index(conn) do
     send_resp(conn, 200, "meows")
   end

   def show(conn) do
     send_resp(conn, 200, "just meow")
   end

   def create(conn) do
     send_resp(conn, 201, "meow!")
   end

   defp assign_kitty_count(conn, _opts) do
     assign(conn, :count, 42)
   end
 end
```

Great, now you can isolate response-building logic in controllers. Running the requested action required a bit of dance, and to build it you really had to get down into the nitty gritty on how requests are routed to controller actions. It's also important to note that the _order_ of the plugs is very imporant here. The assign must happen _before_ the action is applied so that the data is available to build the response.

This is perhaps the most egregious example so far, and it seems like it's about time we start abstracting some framework logic to get these details out of users' faces. Let's starting building Feenix!

## Generating Framework Logic

The "magic" of Phoenix is how it uses Elixir metaprogramming to abstract away the details of how it handles requests and exposing clean abstractions for building applications. You just saw how complicated things got as you introduced controllers to your app. Start moving logic to the framework to hide these details.

### The Endpoint

You'll recall that we ended up with a pretty reasonable endpoint implementation, but it leaks some details about the webserver setup that you can easily get it out of users' faces with a macro.

```diff
 # your_app/endpoint.ex
 defmodule YourApp.Endpoint do
-  def start_link do
-    options = []
-    Plug.Adapters.Cowboy2.http(__MODULE__, options)
-  end
-
-  use Plug.Builder
+  use Feenix.Endpoint

   plug(Plug.Logger)
   plug(YourApp.Router)
 end
```

```elixir
# feenix/endpoint.ex
defmodule Feenix.Endpoint do
  defmacro __using__(_opts) do
    quote do
      def start_link do
        options = []
        Plug.Adapters.Cowboy2.http(__MODULE__, options)
      end

      use Plug.Builder
    end
  end
end
```

That looks much more like a Phoenix endpoint. The final offender is the router.

### The Controller

Controllers in Phoenix don't look much like what we've built so far, they're mostly just modules with functions. By using Elixir's extension mechanisms, `use`, we can extract the controller implementation details to a macro to pass the responsibility on to the framework.

```diff
 # your_app/controller.ex
 defmodule YourApp.Controller do
-  use Plug.Builder
-
-  def call(conn, action) do
-    conn
-    |> put_private(:action, action)
-    |> super(nil)
-  end
+  use Feenix.Controller

   plug(:assign_kitty_count)
-  plug(:apply_action)
-
-  def apply_action(conn, _opts) do
-    apply(__MODULE__, conn.private.action, [conn])
-  end

   def index(conn) do
     send_resp(conn, 200, "meows")
   end

   def show(conn) do
     send_resp(conn, 200, "just meow")
   end

   def create(conn) do
     send_resp(conn, 201, "meow!")
   end

   defp assign_kitty_count(conn, _opts) do
     assign(conn, :count, 42)
   end
 end
```

```elixir
# feenix/controller.ex
defmodule Feenix.Controller do
  defmacro __using__(_opts) do
    quote do
      use Plug.Builder

      def call(conn, action) do
        conn
        |> put_private(:action, action)
        |> super(nil)
      end

      plug(:apply_action)

      def apply_action(conn, _opts) do
        apply(__MODULE__, conn.private.action, [conn])
      end
    end
  end
end
```

Cool, that's look much more like a Phoenix controller. But it does introduce a problem. The problem is the order that the plugs are being made. Now that the framework logic is generated by a single macro, the `:apply_action` plug is happening before our app's `:assign_kitty_count`.

When you test things out you can see the problem.

```sh
$ curl http://localhost:4000/cats

# then in the running terminal

07:45:08.791 [error] #PID<0.298.0> running YourApp.Endpoint (connection #PID<0.297.0>, stream id 1) terminated
Server: localhost:4000 (http)
Request: GET /cats/
** (exit) an exception was raised:
    ** (KeyError) key :count not found in: %{}
        ...
```

So why is `:count` not available in the assigns? It's due to the _order_ that function is plugged. You must have that plug run before the framework plugs `apply_action`, but you can't because everything is defined and plugged behind `use Feenix.Controller`.

Luckily Elixir has a mechanism for exactly this scenario in its `@before_compile` module attribute. This attribute let's to specify a module that defines a special macro to run _just_ before the current module is completely compiled. That's exactly where you would want to `plug(:apply_action)`, as the very last step.

```diff
 # feenix/controller.ex
 defmodule Feenix.Controller do
   defmacro __using__(_opts) do
     quote do
+      @before_compile unquote(__MODULE__)
       use Plug.Builder

       def call(conn, action) do
         conn
         |> put_private(:action, action)
         |> super(nil)
       end
-
-      plug(:apply_action)

       def apply_action(conn, _opts) do
         apply(__MODULE__, conn.private.action, [conn])
       end
     end
   end
+
+  defmacro __before_compile__(_env) do
+    quote do
+      plug(:apply_action)
+    end
+  end
 end
```

Restart your app and see it in action!

```sh
$ curl http://localhost:4000/cats/
42 meows
```

Now that your controllers are looking great, it's time to circle back and attack the test of the app. The endpoint abstraction is pretty straight-forwards. Tackle that next.

### The Router

Remember how your router looks nothing like a Phoenix router? It's full of manual matching logic that you shouldn't have to think much about as a user. It's time to clean up the router and introduce the DSL for defining routes.

Ease into this effort by just abstracting the static parts of the router abstraction first by generating them with a macro. It's important to consider that the router will suffer from the same "early action" bug that you noticed earlier in the controller. That is users must have a chance to add plugs _before_ a request is routed to the controller. So use `@before_action` to solve that problem in the router abstraction as well.

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
-  use Plug.Builder
-  plug(:match)
-
-  def match(conn, _opts) do
-    do_match(conn, conn.method, conn.path_info)
-  end
+  use Feenix.Router

   # get "/cats"
   def do_match(conn, "GET", ["cats"]) do
     YourApp.Controller.call(conn, :index)
   end

   # get "/cats/felix"
   def do_match(conn, "GET", ["cats", "felix"]) do
     YourApp.Controller.call(conn, :show)
   end

   # post "/cats"
   def do_match(conn, "POST" ["cats"]) do
     YourApp.Controller.call(conn, :create)
   end
 end
```

```elixir
# feenix/router.ex
defmodule Feenix.Router do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
      use Plug.Builder

      def match(conn, _opts) do
        do_match(conn, conn.method, conn.path_info)
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      plug(:match)
    end
  end
end
```

### Router DSL

You've pulled all the static behavior you can out into framework code, but your router's dynamic route DSL is still needed. Implement a Phoenix-like DSL for routing `GET` requests.

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
   use Feenix.Router

-  # get "/cats"
-  def do_match(conn, "GET", ["cats"]) do
-    YourApp.Controller.call(conn, :index)
-  end
-
-  # get "/cats/felix"
-  def do_match(conn, "GET", ["cats", "felix"]) do
-    YourApp.Controller.call(conn, :show)
-  end
+  get "/cats", YourApp.Controller, :index
+  get "/cats/felix", YourApp.Controller, :show

   # post "/cats"
   def do_match(conn, "POST" ["cats"]) do
     YourApp.Controller.call(conn, :create)
   end
 end
```

To make this a reality, you will need to import a new DSL macro in the router that generates the match function.

```diff
 # feenix/router.ex
 defmodule Feenix.Router do
   defmacro __using__(_opts) do
     quote do
       @before_compile unquote(__MODULE__)
       use Plug.Builder
+      import Feenix.Router.DSL

       def match(conn, _opts) do
         do_match(conn, conn.method, conn.path_info)
       end
     end
   end

   defmacro __before_compile__(_env) do
     quote do
       plug(:match)
     end
   end
 end
```

```elixir
# feenix/router/dsl.ex
defmodule Feenix.Router.DSL do
  defmacro get(path, module, function) do
    {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

    quote do
      def do_match(conn, "GET", unquote(path_info)) do
        unquote(module).call(conn, unquote(function))
      end
    end
  end
end
```

To support other HTTP verbs, like `POST`, you'll need to generalization the implementation just a little bit.

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
   use Feenix.Router

   get "/cats", YourApp.Controller, :index
   get "/cats/felix", YourApp.Controller, :show
-
-  # post "/cats"
-  def do_match(conn, "POST" ["cats"]) do
-    YourApp.Controller.call(conn, :create)
-  end
+  post "/cats", YourApp.Controller, :create
 end
```

```diff
 # feenix/router/dsl.ex
 defmodule Feenix.Router.DSL do
   defmacro get(path, module, function) do
+    build("GET", path, module, function)
+  end
+
+  defmacro post(path, module, function) do
+    build("POST", path, module, function)
+  end
+
+  def build(method, path, module, function)
     {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

     quote do
-      def do_match(conn, "GET", unquote(path_info)) do
+      def do_match(conn, unquote(method), unquote(path_info)) do
         unquote(module).call(conn, unquote(function))
       end
     end
   end
 end
```

And with one last pass, you might as well extend the DSL to support all the HTTP verbs with one more touch of metaprogramming.

```diff
  # feenix/router/dsl.ex
 defmodule Feenix.Router.DSL do
-  defmacro get(path, module, function) do
-    build("GET", path, module, function)
-  end
-
-  defmacro post(path, module, function) do
-    build("POST", path, module, function)
+  for method <- [:get, :post, :put, :patch, :delete] do
+    defmacro unquote(method)(path, module, function) do
+      method = Plug.Router.Utils.normalize_method(unquote(method))
+      build(method, path, module, function)
+    end
   end

   def build(method, path, module, function)
     {_vars, path_info} = Plug.Router.Utils.build_path_match(path)

     quote do
       def do_match(conn, unquote(method), unquote(path_info)) do
         unquote(module).call(conn, unquote(function))
       end
     end
   end
 end
```

### Bonus: 404

```diff
 # feenix/router.ex
 defmodule Feenix.Router do
   defmacro __using__(_opts) do
     quote do
       @before_compile unquote(__MODULE__)
       use Plug.Builder
       import Feenix.Router.DSL

       def match(conn, _opts) do
         do_match(conn, conn.method, conn.path_info)
       end
     end
   end

   defmacro __before_compile__(_env) do
     quote do
       plug(:match)
+
+      def do_match(conn, _method, _path_info) do
+        send_resp(conn, 404, "not found")
+      end
     end
   end
 end
```

### Bonus: Parameters

```diff
 # your_app/controller.ex
 defmodule YourApp.Controller do
   use Feenix.Controller

   plug(:assign_kitty_count)

-  def index(conn) do
+  def index(conn, _params) do
     send_resp(conn, 200, "#{conn.assigns.count} meows")
   end

-  def show(conn) do
+  def show(conn, _params) do
     send_resp(conn, 200, "just meow")
   end

-  def create(conn) do
-    send_resp(conn, 201, "meow!")
+  def create(conn, %{"name" => name}) do
+    send_resp(conn, 201, "#{name} meow!")
   end

   def assign_kitty_count(conn, _opts) do
     assign(conn, :count, 42)
   end
 end
```

```diff
 # feenix/controller.ex
 defmodule Feenix.Controller do
   defmacro __using__(_opts) do
     quote do
       @before_compile unquote(__MODULE__)

       import Plug.Conn

       use Plug.Builder
+      plug(:fetch_query_params)

       def call(conn, action) do
         conn
         |> put_private(:action, action)
         |> super(nil)
       end

       def apply_action(conn, _opts) do
-        apply(__MODULE__, conn.private.action, [conn])
+        apply(__MODULE__, conn.private.action, [conn, conn.params])
       end
     end
   end

   defmacro __before_compile__(_env) do
     quote do
       plug(:apply_action)
     end
   end
 end
```

### Bonus: Path Parameters

```diff
 # your_app/router.ex
 defmodule YourApp.Router do
   use Feenix.Router

   get "/cats", YourApp.Controller, :index
-  get "/cats/felix", YourApp.Controller, :show
+  get "/cats/:name", YourApp.Controller, :show
   post "/cats", YourApp.Controller, :create
 end
```

```diff
 # your_app/controller.ex
 defmodule YourApp.Controller do
   use Feenix.Controller

   plug(:assign_kitty_count)

   def index(conn, _params) do
     send_resp(conn, 200, "#{conn.assigns.count} meows")
   end

-  def show(conn, _params) do
-    send_resp(conn, 200, "just meow")
+  def show(conn, %{"name" => name}) do
+    send_resp(conn, 200, "#{name} meow")
   end

   def create(conn, %{"name" => name}) do
     send_resp(conn, 201, "created #{name}!")
   end

   def assign_kitty_count(conn, _opts) do
     assign(conn, :count, 42)
   end
 end
```

```diff
 # feenix/router/dsl.ex
 defmodule Feenix.Router.DSL do
   defmacro get(path, module, function) do
     build("GET", path, module, function)
   end

   defmacro post(path, module, function) do
     build("POST", path, module, function)
   end

   def build(method, path, module, function)
-    {_vars, path_info} = Plug.Router.Utils.build_path_match(path)
+    {vars, path_info} = Plug.Router.Utils.build_path_match(path)
+    path_params = Plug.Router.Utils.build_path_params_match(vars)

     quote do
       def do_match(conn, unquote(method), unquote(path_info)) do
+        path_params = unquote({:%{}, [], path_params})
+        conn = update_in(conn.path_params, &Map.merge(&1, path_params))
         unquote(module).call(conn, unquote(function))
       end
     end
   end
 end
```

```diff
 # feenix/controller.ex
 defmodule Feenix.Controller do
   defmacro __using__(_opts) do
     quote do
       @before_compile unquote(__MODULE__)

       import Plug.Conn

       use Plug.Builder
-      plug(:fetch_query_params)
+      plug(Feenix.Controller.Params)

       def call(conn, action) do
         conn
         |> put_private(:action, action)
         |> super(nil)
       end

       def apply_action(conn, _opts) do
         apply(__MODULE__, conn.private.action, [conn, conn.params])
       end
     end
   end

   defmacro __before_compile__(_env) do
     quote do
       plug(:apply_action)
     end
   end
 end
```

```elixir
# feenix/controller/params.ex
defmodule Feenix.Controller.Params do
  use Plug.Builder

  plug(:fetch_query_parameters)
  plug(:merge_params)

  def merge_params(conn, _opts) do
    params = Map.merge(conn.query_params, conn.path_params)
    %{conn | params: params}
  end
end
```

## Summary

So how many lines of framework code did we write?

```
» git diff master --numstat | grep feenix | cut -f1 | paste -sd+ - | bc
77
```
```
» git diff master --stat -- lib/feenix
lib/feenix/controller.ex | 27 ++++++++++++++++++++++++++-
lib/feenix/endpoint.ex   | 12 +++++++++++-
lib/feenix/router.ex     | 41 ++++++++++++++++++++++++++++++++++++++++-
3 files changed, 77 insertions(+), 3 deletions(-)
```

