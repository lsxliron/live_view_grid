defmodule LiveViewGrid.Components.DateFilter do
  use Phoenix.LiveComponent
  use LiveViewGrid.Behaviours.BaseFilterComponent, default_filter_type: "before", filter_type: :date
  require Logger

  def get_options() do
    [
      Before: "before",
      After: "after",
      Equals: "equals",
      "Not Equals": "not_equals",
      Blank: "blank",
      "Not Blank": "not_blank"
    ]
  end
end
