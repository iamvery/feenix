# Let's Build a Phoenix!

When you get started with Elixir Phoenix, you'll often hear "it's just a function pipeline!" Okay! But when you look at an app, it doesn't really _look_ like it. Is it? If so, how? Let's dive it!

Here's an example of a basic Phoenix application:

```elixir
# endpoint.ex
defmodule YourApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :your_app
  
  # various plugs
  plug(YourApp.Router)
end
```

```elixir
# router.ex
defmodule YourApp.Router do
  use YourAppWeb, :router
  
  get "/cats", YourApp.Controller, :index
  get "/cats/felix", YourApp.Controller, :show
  post "/cats", YourApp.Controller, :create
end
```

```elixir
# controller.ex
defmodule YourApp.Controller do
  use YourAppWeb, :controller
  
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

You can sort of see how the router is _plugged_ into the the endpoint, and it sort of seems to delegate to the controller for certain requests. But routers are very declarative. How does that work? In a word, metaprogramming. Phoenix uses Elixir's rich metaprogramming model to surface a simple DSL for _declaring_ routes so that you don't to fool with the pattern-matching underpinnings of its implementation.

## The Endpoint

The entry point for a request in a Phoenix app is the _endpoint_. That's it, the first step. What purpose does an endpoint serve? Let me name them:

1. It sets up the Elixir web server to handle requests.
2. It preprocesses the request in various ways. Rubiests think: Rack middleware. This includes things like handling static assets, implementing HTTP method override, and logging requests. (take a peek at the generated endpoint.ex in your Phoenix projects)
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

Now you can pipe a connection through your endpont!

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
+    Plug.Conn.put_private(conn, :name, "world")
   end
  
   def world(conn, _opts) do
-    IO.puts("world")
-    conn
+    Plug.Conn.send_resp(conn, 200, "hello #{conn.private.name}")
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

That's about it for the endpoint, but as you can see from the request we sent our app, there is no concept of request path or routing happening. Enter the router...

## The Router

//