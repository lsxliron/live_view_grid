defmodule LiveViewGrid.TestGrid do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    cols =
      [
        %LiveViewGrid.Column{field: "text", data_type: :text},
        %LiveViewGrid.Column{field: "date", data_type: :date},
        %LiveViewGrid.Column{field: "number", data_type: :number}
      ]
      |> Enum.map(&LiveViewGrid.Column.init/1)

    test_data = [
      %{"date" => ~U[2024-01-10T00:00:00Z], "text" => "abc", "number" => 100},
      %{"date" => ~U[2024-02-10T00:00:00Z], "text" => "def", "number" => 200},
      %{"date" => ~U[2024-03-10T00:00:00Z], "text" => "hij", "number" => 300}
    ]

    {:ok,
     socket
     |> assign(%{
       cols: cols,
       data: test_data,
       total_pages: 1,
       current_page: 1,
       total_rows: length(test_data),
       order_by: OrdMap.new(),
       filter_by: []
     })}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={LiveViewGrid}
      id="test-grid"
      cols={@cols}
      data={@data}
      total_pages={@total_pages}
      total_rows={@total_rows}
      current_page={@current_page}
      order_by={@order_by}
      filter_by={@filter_by}
    />
    """
  end
end
