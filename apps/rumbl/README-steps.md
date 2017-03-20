## Elixir Struct

```ex
defmodule Rumbl.User do
  defstruct [:id, :name, :username, :password]
end

alias Rumbl.User

user = %{usernmae: "jose", password: "elixir"}
user.username
# ** (KeyError) key :username not found in: %{password: "elixir", usernmae: "jose"}

jose = %User{name: "Jose Valim"}
jose.name # "Jose Valim"

chris = %User{nmae: "chris"}
#** (CompileError) iex:3: unknown key :nmae for struct User
#
```

## Router

```ex
  # ...
  scope "/", Rumbl do
    pipe_through :browser # Use the default browser stack

    #using resources
    resources "/users", UserController, only: [:index, :show, :new, :create]

    # hardcoded
    get "/users", UserController, :index
    get "/users/:id/edit", UserController, :edit
    get "/users/new", UserController, :new
    get "/users/:id", UserController, :show
    post "/users", UserController, :create
    patch "/users/:id", UserController, :update
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete

    get "/", PageController, :index
  end
  # ...
```

```bash
mix phoenix.routes
```

## Ecto

`iex -S mix`

```ex
alias Rumbl.Repo
alias Rumbl.User

Repo.insert(%User{name: "Jose", username: "josevalim", password_hash: "<3<3elixir"})
Repo.all(User)
Repo.get(User, 1)

```


## Render template in iex

this can be a partial or entire template

```ex
user = Rumbl.Repo.get(Rumbl.User,"1") 
view = Rumbl.UserView.render("user.html", user: user)
Phoenix.HTML.safe_to_string(view)
```


## Memory based repo

add `web/models/user.ex`

```ex
defmodule User do
  defstruct [:id, :name, :username, :password]
end
```

edit: `lib/rumbl.ex`

```ex
defmodule Rumbl.Repo do
  # use Ecto.Repo, otp_app: :rumbl

  def all(Rumbl.User) do
    [%Rumbl.User{id: "1", name: "José", username: "josevalim", password: "elixir"},
     %Rumbl.User{id: "2", name: "Bruce", username: "redrapids", password: "7langs"},
     %Rumbl.User{id: "3", name: "Chris", username: "chrismccord", password: "phx"}]
  end
  def all(_module), do: []

  def get(module, id) do
    Enum.find all(module), fn map -> map.id == id end
  end

  def get_by(module, params) do
    Enum.find all(module), fn map ->
      Enum.all?(params, fn {key, val} -> Map.get(map, key) == val end)
    end
  end
end
```

edit `lib/rumbl.ex`

```ex
defmodule Rumbl do
  # ...

  def start(_type, _args) do
    # ...

    children = [
      # ...
      # supervisor(Rumbl.Repo, []),  #comment out this line
      # ...
    ]

    # ...
```

```bash
$ iex -S mix
iex(1)> alias Rumbl.User
Rumbl.User
iex(2)> alias Rumbl.Repo
Rumbl.Repo
iex(3)> Repo.all User
[%Rumbl.User{id: "1", name: "José", password: "elixir", username: "josevalim"},
 %Rumbl.User{id: "2", name: "Bruce", password: "7langs", username: "redrapids"},
 %Rumbl.User{id: "3", name: "Chris", password: "phx", username: "chrismccord"}]
```
source code: https://github.com/equivalent/rumbl/tree/01-memory-based-repo (be sure you stay on branch `01-memory-based-repo`)

## Changeset

```exs
ch = User.registration_changeset(%User{}, %{username: "max", name: "Max", password: "123"})
ch.valid? # false

# update existing records
for u <- Rumbl.Repo.all(User) do
  Rumbl.Repo.update!(User.registration_changeset(u, %{password: u.password_hash || "temppass"}))
end
```


## Generators

```
mix phoenix.gen.html Video videos user_id:references:users url:string title:string description:text
mix ecto.migrate
mix ecto.rollback
```


## Relationships

`iex -S mix`

```ex
alias Rumbl.Repo
alias Rumbl.User
import Ecto.Query

user = Repo.get_by!(User, username: "josevalim")
user.videos
# > #Ecto.Association.NotLoaded<association :videos is not loaded>
user = Repo.preload(user, :videos)
user.videos
# > []

# add
attrs = %{title: "hi", description: "says hi", url: "example.com"}
video = Ecto.build_assoc(user, :videos, attrs)
video = Repo.insert!(video)

# retriew newly added
user = Repo.get_by!(User, username: "josevalim")
user = Repo.preload(user, :videos) 
user.videos

# alternative way
query = Ecto.assoc(user, :videos)
Repo.all(query)

Repo.all(Ecto.assoc(user, :videos))       # all videos of a user
Repo.get!(Ecto.assoc(user, :videos), 123) # video of a user with ID


# therefore in controller we can do this:
defmodule Rumbl.VideoController do
  use Rumbl.Web, :controller
  alias Rumbl.Video

  def new(conn, _params) do
    changeset =
      conn.assigns.current_user
      |> build_assoc(:videos)
      |> Video.changeset()
    render(conn, "new.html", changeset: changeset)
  end
  # ...
end

```



## ecto queries and constraints

```
mix phoenix.gen.model Category categories name:string
mix ecto.gen.migration add_category_id_to_video

mix run priv/repo/seeds.exs
```

```ex
Repo.all from c in Category, select: c.name
# SELECT c0."name" FROM "categories" AS c0 []
# => ["Action", "Drama", "Romance", "Comedy", "Sci-fi"]

Repo.all from c in Category, select: c.name, order_by: name
# SELECT c0."name" FROM "categories" AS c0 ORDER BY c0."name" []
# => ["Action", "Comedy", "Drama", "Romance", "Sci-fi"]


query = Category
query = from c in query, order_by: c.name
query = from c in query, select: {c.name, c.id}
Repo.all query
# SELECT c0."name", c0."id" FROM "categories" AS c0 ORDER BY c0."name" []
# => [{"Action", 1}, {"Comedy", 4}, {"Drama", 2}, {"Romance", 3}, {"Sci-fi", 5}]

```

```ex
import Ecto.Query
alias Rumbl.Repo
alias Rumbl.User

username = 123
Repo.all(from u in User, where: u.username == ^username)
```

* Comparison operators: == , != , <= , >= , < , >
* Boolean operators: `and` , `or` , `not`
* Inclusion operator: `in`
* Search functions: `like` and `ilike`
* Null check functions: `is_nil`
* Aggregates: `count` , `avg` , `sum` , `min` , `max`
* Date/time intervals: `datetime_add` , `date_add`
* General: `fragment` , `field` , and `type`


```ex
Repo.one(from u in User, select: count(u.id), where: ilike(u.username,^"j%") or ilike(u.username, ^"c%"))
# SELECT count(u0."id") FROM "users" AS u0 WHERE ((u0."username" ILIKE $1) OR (u0."username" ILIKE $2)) ["j%", "c%"]


users_count = from u in User, select: count(u.id)
j_users = from u in users_count, where: ilike(u.username, ^"%j%")
Repo.all(j_users)
```

### using pipe operator

```ex
User |> select([u], count(u.id)) |> where([u], ilike(u.username, ^"j%") or ilike(u.username, ^"c%")) |> Repo.one
# SELECT count(u0."id") FROM "users" AS u0 WHERE ((u0."username" ILIKE $1) OR (u0."username" ILIKE $2)) ["j%", "c%"]
1
```

### fragmests

```ex
from(u in User, where: fragment("lower(username) = ?", ^String.downcase(uname)))

```

### Direct sql execution

```ex
Ecto.Adapters.SQL.query(Rumbl.Repo, "SELECT power($1, $2)", [2, 10])
```

### preload association in same step 

similar to preload example above

```ex
user = Repo.one from(u in User, limit: 1, preload: [:videos])

```


```ex
Repo.all from u in User,
    join: v in assoc(u, :videos),
    join: c in assoc(v, :category),
   where: c.name == "Comedy",
  select: {u, v}

# > [{%Rumbl.User{...}, %Rumbl.Video{...}}]
```


```ex
alias Rumbl.Category
alias Rumbl.Video
alias Rumbl.Repo
import Ecto.Query
category = Repo.get_by Category, name: "Drama"
# SELECT c0."id", c0."name", c0."inserted_at", c0."updated_at" FROM "categories" AS c0 WHERE (c0."name" = $1) ["Drama"]
# %Rumbl.Category{__meta__: #Ecto.Schema.Metadata<:loaded, "categories">, id: 2,
#   inserted_at: ~N[2017-02-19 20:05:54.008550], name: "Drama",
#   updated_at: ~N[2017-02-19 20:05:54.008556]}

video = Repo.one(from v in Video, limit: 1)
# SELECT v0."id", v0."url", v0."title", v0."description", v0."user_id", v0."category_id", v0."inserted_at", v0."updated_at" FROM "videos" AS v0 LIMIT 1 []
# %Rumbl.Video{__meta__: #Ecto.Schema.Metadata<:loaded, "videos">,
#   category: #Ecto.Association.NotLoaded<association :category is not loaded>,
#   category_id: nil, description: "says hi", id: 1,
#   inserted_at: ~N[2017-02-19 16:41:28.198196], title: "hi",
#   updated_at: ~N[2017-02-19 16:41:28.208806], url: "example.com",
#   user: #Ecto.Association.NotLoaded<association :user is not loaded>, user_id: 1}
changeset = Video.changeset(video, %{category_id: category.id})
#Ecto.Changeset<action: nil, changes: %{category_id: 2}, errors: [], data: #Rumbl.Video<>, valid?: true>
Repo.update(changeset)
#   [debug] QUERY OK db=0.7ms queue=0.2ms
#   begin []
#   [debug] QUERY OK db=3.7ms
#   UPDATE "videos" SET "category_id" = $1, "updated_at" = $2 WHERE "id" = $3 [2, {{2017, 2, 21}, {19, 39, 44, 929090}}, 1]
#   [debug] QUERY OK db=3.3ms
#   commit []
# {:ok,
#   %Rumbl.Video{__meta__: #Ecto.Schema.Metadata<:loaded, "videos">,
#     category: #Ecto.Association.NotLoaded<association :category is not loaded>,
#     category_id: 2, description: "says hi", id: 1,
#     inserted_at: ~N[2017-02-19 16:41:28.198196], title: "hi",
#     updated_at: ~N[2017-02-21 19:39:44.929090], url: "example.com",
#     user: #Ecto.Association.NotLoaded<association :user is not loaded>,
#     user_id: 1}}
changeset = Video.changeset(video, %{category_id: 12345})
# #Ecto.Changeset<action: nil, changes: %{category_id: 12345}, errors: [],
#   data: #Rumbl.Video<>, valid?: true>
# iex(10)> Repo.update(changeset)
#   [debug] QUERY OK db=0.7ms queue=0.2ms
#   begin []
#   [debug] QUERY ERROR db=12.8ms
#   UPDATE "videos" SET "category_id" = $1, "updated_at" = $2 WHERE "id" = $3 [12345, {{2017, 2, 21}, {19, 40, 2, 386567}}, 1]
#   [debug] QUERY OK db=0.3ms
#   rollback []
# {:error,
# #Ecto.Changeset<action: :update, changes: %{category_id: 12345},
# errors: [category: {"does not exist", []}], data: #Rumbl.Video<>,
#         valid?: false>}
{:error, changeset} = v(-1)  # get the previous value
# {:error,
#  #Ecto.Changeset<action: :update, changes: %{category_id: 12345},
#   errors: [category: {"does not exist", []}], data: #Rumbl.Video<>,
#   valid?: false>}
changeset.errors
# [category: {"does not exist", []}]
```



### delece constraint

```ex
import Ecto.Changeset
changeset = Ecto.Changeset.change(category)
changeset = foreign_key_constraint(changeset, :videos, name: :videos_category_id_fkey, message: "still exist")
Repo.delete changeset

```

###  taged test run

```
$ mix test test/controllers --only login_as
```


### generate annotation model

```
mix phoenix.gen.model Annotation annotations body:text at:integer user_id:references:users video_id:references:videos
```

### basic OTP

on branch `08-basic-otp`

```
alias Rumbl.Counter

{:ok, counter} = Counter.start_link(0)
# => {:ok, #PID<0.276.0>}

Counter.inc(counter)
Counter.inc(counter)
Counter.inc(counter)
Counter.dec(counter)

Counter.val(counter)
# => 2

Counter.dec(counter)
Counter.val(counter)
# => 1
```

### basic GenServer

on branch `09-basic-genserver`

```
alias Rumbl.Counter
# => Rumbl.Counter
{:ok, counter} = Counter.start_link(10)

Counter.dec(counter)
Counter.dec(counter)
Counter.inc(counter)
Counter.val
# => 9
```

### basic OTP supervision

```
# lib/rumbl.ex

# ...
    children = [
      # Start the Ecto repository
      supervisor(Rumbl.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Rumbl.Endpoint, []),
      # Start your own worker by calling: Rumbl.Worker.start_link(arg1, arg2, arg3)
      # worker(Rumbl.Worker, [arg1, arg2, arg3]),
      worker(Rumbl.Counter, [5], restart: :temporary, id: 1),
      worker(Rumbl.Counter, [5], restart: :permanent, id: 2),
      worker(Rumbl.Counter, [5], restart: :permanent, id: 3, max_restarts: 1, max_seconds: 12 ),
    ]

# ...
```

* `:permanent` - The child is always restarted (default).
* `:temporary` - The child is never restarted.
* `:transient` - The child is restarted only if it terminates abnormally, with an exit reason other than `:normal` , `:shutdown` , or `{:shutdown, term}`.

OTP will only restart an application `max_restarts` times in `max_seconds` before
failing and reporting the error up the supervision tree. By default, Elixir will
allow 3 restarts in 5 seconds, but you can configure these values to whatever
you want. In general, you’ll use the restart strategies your specific application
requires.


supervizor strategies: 

* `:one_for_one` - If a child terminates, a supervisor restarts only that process.
* `:one_for_all` - If a child terminates, a supervisor terminates all children and then restarts
all children.
* `:rest_for_one` - If a child terminates, a supervisor terminates all child processes defined
after the one that dies. Then the supervisor restarts all terminated pro-
cesses.
* `:simple_one_for_one` - Similar to :one_for_one but used when a supervisor needs to dynamically
supervise processes. For example, a web server would use it to supervise
web requests, which may be 10, 1,000, or 100,000 concurrently running
processes.


### Agent

Agent is simple GenServer OTP 

PID agent :

```
import Agent

{:ok, agent} = start_link fn -> 5 end

update agent, &(&1 + 1)
# => :ok
get agent, &(&1)
# => 6

stop agent
# => :ok
```

Named Agent:


```
import Agent

{:ok, _agent} = start_link fn -> 5 end, name: MyAgent

update MyAgent, &(&1 + 1)
# => :ok
get  MyAgent, &(&1)
# => 6

stop MyAgent
# => :ok
```

### Monitor spawn process

```
pid = spawn(fn -> :ok end)
# => #PID<0.530.0>
Process.monitor(pid)
# => #Reference<0.0.1.4941>
flush()
# {:DOWN, #Reference<0.0.1.4941>, :process, #PID<0.530.0>, :noproc}
# => :ok

```


### Wolfram alfa 

```
Rumbl.InfoSys.compute("what is the meaning of life?")
# => [%Rumbl.InfoSys.Result{backend: "wolfram", score: 95, text: "42\n(according to the book The Hitchhiker", url: nil}]

# flush() # is empty now

```


### timeout

```
receive do
  :this_will_never_arrive -> :ok
after
  1_000 -> :timedout
end
# => :timedout
```

careful this `after` approach is cumlative => if 5 blocks will implement
it it may end up 5 seconds

### Wolfram user seed

```
mix run priv/repo/backend_seeds.ex
```

### observer manager

```
:observer.start
```

### umbrella projects

(outside rumbl application)

```
mix new rumbrella --umbrella
cd apps
mix new info_sys --sup
cd info_sys
```
