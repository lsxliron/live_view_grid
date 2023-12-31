defmodule LiveViewGrid.Behaviours.BaseFilter do
  @callback get_query(struct(), String.t()) :: map() | nil
  @callback get_subquery(String.t(), String.t(), String.t()) :: map()
end
