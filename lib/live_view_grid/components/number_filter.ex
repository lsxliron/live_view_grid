defmodule LiveViewGrid.Components.NumberFilter do
  use Phoenix.LiveComponent
  use LiveViewGrid.Behaviours.BaseFilter, default_filter_type: "greater", filter_type: :number

  def get_options() do
    [
      "Greater Than": "greater",
      "Greater Than Eq.": "greater_equal",
      "Less Than": "less",
      "Less Than Eq.": "less_equal",
      Equals: "equals",
      "Not Equals": "not_equals",
      Blank: "blank",
      "Not Blank": "not_blank"
    ]
  end
end
