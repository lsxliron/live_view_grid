# cspell: ignore trunc
defmodule LiveViewGrid.Utils do
  import Phoenix.Component, only: [assign: 3, assign_new: 3]
  import Phoenix.LiveView, only: [connected?: 1, push_patch: 2, put_flash: 3]
  require Logger

  @type query_result :: %{
          required(:pagination) => %{
            required(:total_pages) => non_neg_integer(),
            required(:total) => non_neg_integer()
          }
        }

  @doc """
  Returns the total number of pages in the dataset
  """
  @spec get_total_pages(query_result) :: non_neg_integer()
  def get_total_pages(data) do
    if length(data["pagination"]) > 0 do
      data
      |> Map.get("pagination")
      |> Enum.at(0)
      |> Map.get("total_pages")
      |> trunc()
    else
      1
    end
  end

  # Make sure if rows do not exists we specify it explicitly
  # since in some cases the array comes back empty

  @doc """
  Returns the total number of rows in the dataset
  """
  @spec get_total_rows(query_result) :: non_neg_integer()
  def get_total_rows(data) do
    if length(data["pagination"]) > 0 do
      data
      |> Map.get("pagination")
      |> Enum.at(0)
      |> Map.get("total")
      |> trunc()
    else
      0
    end
  end

  @doc """
  Adds basic sorting to MongoDB aggregation query based on the `order_by` attribute in `socket.assigns`

  ## Parameters
  - `query` - the aggregation query
  - `socket` - the socket to get the `assigns` from

  ## Example
  ```
  iex> order_by = [{:col1, 1}, {:col2, -1}]
  iex> socket = %Phoenix.LiveView.Socket{} |> Phoenix.Component.assign(:order_by, order_by)
  iex> query = [%{
  ...>   "$project": %{
  ...>     _id: 1,
  ...>     col1: 1,
  ...>     col2: 2
  ...>   }
  ...> }]
  iex> add_basic_order_by(query, socket)
  [
    %{
      "$sort": %{
        col1: 1,
        col2: -1
      }
    },
    %{
      "$project": %{
        _id: 1,
        col1: 1,
        col2: 2
      }
    }
  ]
  ```
  """
  @spec add_basic_order_by(list(), Phoenix.LiveView.Socket.t()) :: list()
  def add_basic_order_by(query, socket) do
    case OrdMap.keys(socket.assigns.order_by) |> length do
      0 ->
        query

      _ ->
        List.insert_at(query, length(query) - 1, %{
          "$sort": socket.assigns.order_by |> Enum.into(%{})
        })
    end
  end

  @doc ~S"""
  Adds basic filtering to MongoDB aggregation query based on the `filter_by` attribute in `socket.assigns`

  ## Parameters
  - `query` - the aggregation query
  - `socket` - the socket to get the `assigns` from
  ```
  """
  @spec add_basic_filter(list(), Phoenix.LiveView.Socket.t()) :: list()
  def add_basic_filter(query, socket) do
    # TODO: document, this is new implementation
    active_filters =
      socket.assigns.cols
      |> Enum.filter(&(&1.filter.enabled == true))
      |> Enum.map(fn col ->
        case col.data_type do
          :text -> LiveViewGrid.Filters.Text.get_query(col.filter, col.field)
          :date -> LiveViewGrid.Filters.Date.get_query(col.filter, col.field)
          :number -> LiveViewGrid.Filters.Number.get_query(col.filter, col.field)
        end
      end)

    Logger.debug("active filters: #{inspect(active_filters)}")

    if length(active_filters) == 0 do
      query
    else
      match = %{"$match": %{"$and": active_filters}}
      List.insert_at(query, length(query) - 1, match)
    end
  end

  @doc """
  Calls the `get_data/2` function and set the proper assigns for the pagination

  ## Parameters
  - `socket` - the LiveView socket
  - `page` - the page number to fetch the data for
  """
  @spec paginate(Phoenix.LiveView.Socket.t(), non_neg_integer()) :: Phoenix.LiveView.Socket.t()
  def paginate(socket, page) do
    {items, total_rows, total_pages} = socket.assigns.get_data.(page, socket)

    socket =
      socket
      |> assign(:total_pages, total_pages)
      |> assign(:data, items)
      |> assign(:total_rows, total_rows)

    cond do
      socket.assigns.current_page < 1 ->
        socket
        |> put_flash(:error, "#{socket.assigns.current_page} is not a valid page")
        |> push_patch(to: "#{socket.assigns.prefix}/?page=1")

      socket.assigns.current_page > total_pages and total_pages != 0 ->
        socket
        |> put_flash(:error, "#{socket.assigns.current_page} is not a valid page")
        |> push_patch(to: "#{socket.assigns.prefix}/?page=#{total_pages}")

      true ->
        socket
    end
  end

  # TODO: move to utils, will be needed in other screens
  @doc """
  Parses the page number

  ## Examples
  ```
  iex> parse_page("12")
  {:ok, 12}

  iex> parse_page("12A")
  {:error, 1}
  ```
  """
  @spec parse_page(String.t()) :: {:ok, non_neg_integer()} | {:error, non_neg_integer()}
  def parse_page(page) do
    case Integer.parse(page) do
      {p, ""} -> {:ok, p}
      _ -> {:error, 1}
    end
  end

  @doc false
  def handle_params(params, uri, socket) do
    # adds the `page` url parameter
    if not connected?(socket) do
      {:noreply, socket}
    else
      prefix = get_prefix(uri, socket)
      socket = socket |> assign_new(:prefix, fn _ -> prefix end)

      # If page is not provided, redirect to the first page
      case Map.get(params, "page") do
        nil ->
          {:noreply, socket |> push_patch(to: "#{prefix}/?page=1")}

        page ->
          case parse_page(page) do
            {:ok, p} ->
              {:noreply, socket |> assign(:current_page, p) |> paginate(p)}

            {:error, _p} ->
              {:noreply,
               socket
               |> put_flash(:error, "#{page} is not a valid page number")
               |> push_patch(to: "#{prefix}/?page=1")}
          end
      end
    end
  end

  @doc """
  Updates the filter_by attribute in the `assigns` and fires get_data

  ## Parameters
  - `params` - a map where the keys are the attributes names and the values are string to filter by
  - `socket` - the LiveView socket
  """
  @spec filter(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def filter(params, socket) do
    filter_by =
      params
      |> Map.delete("_target")
      |> Enum.map(fn {k, v} -> {k, String.trim(v)} end)
      |> Enum.filter(fn {_k, v} -> v != "" end)
      |> Enum.into(%{})

    {:noreply,
     socket
     |> assign(:filter_by, filter_by)
     |> assign(:current_page, 1)
     |> push_patch(to: "#{socket.assigns.prefix}/?page=1")}
  end

  @spec column_sorter(list(String.t())) :: fun()
  def column_sorter(all_columns) do
    fn col_def ->
      Enum.find_index(all_columns, &(col_def.header == &1))
    end
  end

  @doc """

  Updated the columns order

  ## Parameters
  - `columns` - a list with the new columns order
  - `socket` - the LiveView socket
  """
  @spec set_columns(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def set_columns(%{"columns" => columns} = _params, socket) do
    Logger.debug("re-organizing columns")
    sorter = column_sorter(columns)
    cols = socket.assigns.cols |> Enum.sort_by(sorter)
    {:noreply, socket |> assign(:cols, cols)}
  end

  @doc """
  Logs the query in a readable format
  """
  @spec log_query(list() | map()) :: :ok
  def log_query(query) do
    query
    |> Phoenix.json_library().encode!(pretty: true)
    |> String.replace("\n", "")
    |> String.replace(~r/\s+/, "")
    |> String.replace(":", ": ")
    |> Logger.debug()
  end

  @doc """
  Cycles through the sort order for a single column (`1` for ascending, `-1` for descending or `nil`)

  ## Parameters
  - `column` - the column to update the sort order for
  - `socket` - the LiveView socket
  """
  @spec update_sort(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}
  def update_sort(%{"column" => column} = _params, socket) do
    column = column |> String.to_existing_atom()

    updated_order_by =
      case OrdMap.get(socket.assigns.order_by, column, nil) do
        1 -> OrdMap.put(socket.assigns.order_by, column, -1)
        -1 -> OrdMap.delete(socket.assigns.order_by, column)
        nil -> OrdMap.put(socket.assigns.order_by, column, 1)
      end

    {:noreply,
     socket
     |> assign(:order_by, updated_order_by)
     |> paginate(socket.assigns.current_page)}
  end

  @doc """
  Extracts the host from the URI object

  ## Parameters
  - `socket` - the LiveView socket

  ## Examples
  ```iex
  iex> host_uri = %URI{scheme: "http", host: "localhost", port: nil}
  iex> socket = %Phoenix.LiveView.Socket{host_uri: host_uri}
  iex> get_host(socket)
  "http://localhost"

  iex> host_uri = %URI{scheme: "https", host: "localhost", port: 443}
  iex> socket = %Phoenix.LiveView.Socket{host_uri: host_uri}
  iex> get_host(socket)
  "https://localhost"

  iex> host_uri = %URI{scheme: "http", host: "localhost", port: 4000}
  iex> socket = %Phoenix.LiveView.Socket{host_uri: host_uri}
  iex> get_host(socket)
  "http://localhost:4000"
  ```
  """
  @spec get_host(Phoenix.LiveView.Socket.t()) :: String.t()
  def get_host(socket) do
    %{scheme: scheme, host: host, port: port} = socket.host_uri

    case socket.host_uri.port do
      p when p == 80 or p == 443 or is_nil(p) -> "#{scheme}://#{host}"
      _ -> "#{scheme}://#{host}:#{port}"
    end
  end

  @doc """
  Returns the URI prefix without the host

  ## Parameters
  - `uri` - the full current URI
  - `socket` - the LiveView socket

  ## Examples

  ```
  iex> host_uri = %URI{
  ...>     scheme: "https",
  ...>     host: "my-site.com",
  ...>     port: 443
  ...>   }
  iex> uri = "https://my-site.com/path/to/grid?page=1"
  iex> socket = %Phoenix.LiveView.Socket{host_uri: host_uri}
  iex> get_prefix(uri, socket)
  "/path/to/grid"
  ```

  """
  @spec get_prefix(String.t(), Phoenix.LiveView.Socket.t()) :: String.t()
  def get_prefix(uri, socket) do
    host = get_host(socket)

    String.replace(uri, host, "")
    |> String.split("?")
    |> Enum.at(0)
    |> String.trim_trailing("/")
  end

  @doc """
  Initializes the required assigns for the grid to work properly

  - `:cols` - a map where the keys are the columns attributes and the values are the columns labels (e.g. `%{"my_column" => "My Column"}`)
  - `:current_page` - the current page
  - `:order_by` - a list of tuples of columns to sort by (see `add_basic_order_by/2`)
  - `:per_page` - the number of rows to show per page
  - `:total_pages` - total number of pages
  - `:total_rows` - total number of rows
  """
  @spec init_grid(Phoenix.LiveView.Socket.t(), list(LiveViewGrid.Column.t())) :: Phoenix.LiveView.Socket.t()
  def init_grid(socket, cols) do
    initialized_cols = cols |> Enum.map(&LiveViewGrid.Column.init/1)

    socket
    |> assign(:cols, initialized_cols)
    |> assign_new(:current_page, fn _ -> 1 end)
    |> assign_new(:filter_by, fn _ -> %{} end)
    |> assign_new(:order_by, fn _ -> OrdMap.new(%{}) end)
    |> assign_new(:per_page, fn _ -> 100 end)
    |> assign_new(:total_pages, fn _ -> 1 end)
    |> assign_new(:total_rows, fn _ -> 1 end)
  end

  @doc """
  Returns the required query fragment to add the pagination details

  ## Parameters
  - `page` - the current page number
  - `per_page` - the number of items per page


  ## Example
  ```
  iex> get_facet(1, 50)
  %{
    "$facet": %{
      pagination: [
        %{"$count": "total"},
        %{"$addFields": %{page: 1, total_pages: %{"$ceil": %{"$divide": ["$total", 50]}}}}
      ],
      results: [%{"$skip": 0}, %{"$limit": 50}]
    }
  }
  ```
  """
  @spec get_facet(non_neg_integer(), non_neg_integer()) :: map()
  def get_facet(page, per_page) do
    %{
      "$facet": %{
        results: [%{"$skip": (page - 1) * per_page}, %{"$limit": per_page}],
        pagination: [
          %{
            "$count": "total"
          },
          %{
            "$addFields": %{
              page: 1,
              total_pages: %{"$ceil": %{"$divide": ["$total", per_page]}}
            }
          }
        ]
      }
    }
  end

  @doc """
  Returns the proper filter module based on the provided filter type.
  Valid filter types are `:text`, `"test"`, `:date`, `"date"` `:number` and `"number"`

  ## Parameters
  - `m` - the filter_type type
  """
  @spec get_filter_module(String.t() | atom()) :: module()
  def get_filter_module(filter_type) do
    case filter_type do
      v when v in ["text", :text] -> LiveViewGrid.Filters.Text
      v when v in ["date", :date] -> LiveViewGrid.Filters.Date
      v when v in ["number", :number] -> LiveViewGrid.Filters.Number
    end
  end
end
