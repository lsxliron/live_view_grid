<!-- cspell: ignore defmodule -->
# LiveViewGrid

**TODO: Add description**

## Installation

<!--
If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_view_grid` to your list of dependencies in `mix.exs`:
-->

Add the following to the application dependencies

```elixir
def deps do
  [
    {:live_view_grid, "~> 0.0.1a"}
  ]
end
```

<!--Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/live_view_grid>. -->


## Setup
1. Edit your application `endpoint.ex` and enable your application to load the static assets of the grid

   ```elixir
   plug Plug.Static,
       at: "/assets",
       from: :live_view_grid,
       gzip: false
   ```

2. Add the grid stylesheet to the desired layout file (e.g. `root.html.heex`)
   ```elixir
   <link phx-track-static rel="stylesheet" href={~p"/assets/live_view_grid.css"} />
   ```

## Usage

```elixir
defmodule MyGrid do
  use Phoenix.LiveView
  # use default implementation for callbacks
  use LiveViewGrid.Defaults

  def get_data(_page, _socket) do
    # fetch data from remote source and
    # return {items, total_rows, total_pages}
    {[%{"a" => 1, "b" => 2, "c" => 3, "d" => 4}], 1, 1}
  end

  def mount(_params, _session, socket) do
    cols = [
      {"a", "A"},
      {"b", "B"},
      {"c", "C"},
      {"d", "D"},
    ]

    {:ok,
     socket
     |> assign(:data, [])
     |> assign(:get_data, &get_data/2)
     |> LiveViewGrid.Utils.init_grid(cols)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
        module={LiveViewGrid}
        id="my-grid"
        cols={@cols}
        data={@data}
      />
    """
  end
end
```
The grid component takes the following attributes:

1. `grid_id` - the component ID (required)
1. `data` - an array of maps where every map is a row in the grid  (required)
1. `cols` - a list of tuples where the first tuple element is the attribute name and
the second one is the rendered name (e.g. `{"total_items", "Total Items"}`)

## Default Callbacks
The grid responds to the following callbacks:

```elixir
def handle_event("set-columns", %{"columns" => columns}=_params, socket) do
  # triggered every time that the column order is changing
  # default implementation in LiveViewGrid.Utils.set_columns/2
end

def handle_event("filter", params, socket) do
  # triggered when filters are modified
  # default implementation in LiveViewGrid.Utils.filter/2
end

def handle_event("update-sort", %{"column" => column} = _params, socket) do
# triggered when sort order  modified
  # default implementation in LiveViewGrid.Utils.update_sort/2
end
```

In addition, the `handle_params/3` callback is used and the default implementation 
can be found in `LiveViewGrid.Utils.handle_params/3`