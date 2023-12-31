# cspell: ignore subquery
defmodule LiveViewGrid.Behaviours.BaseFilter do
  @moduledoc """
  A simple behaviour to implement a filter. The `get_query` is being executed every time the grid want to get a certain query for a filter.
  The `get_subquery` callback is being executed once for every condition in the filter.
  """
  @callback get_query(struct(), String.t()) :: map() | nil
  @callback get_subquery(String.t(), String.t(), String.t()) :: map()
end
