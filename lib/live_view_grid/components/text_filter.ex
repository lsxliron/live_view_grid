defmodule LiveViewGrid.Components.TextFilter do
  use Phoenix.LiveComponent
  use LiveViewGridWeb.Behaviours.BaseFilter, default_filter_type: "contains", filter_type: :text

  def get_options() do
    [
      Contains: "contains",
      "Not Contains": "not_contains",
      Equals: "equals",
      "Not Equals": "not_equals",
      Blank: "blank",
      "Not Blank": "not_blank"
    ]
  end
end
