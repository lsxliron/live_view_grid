defmodule LiveViewGrid do
  use Phoenix.LiveComponent
  require Logger

  @moduledoc """
  A tabular grid to render data
  """

  def get_filter_component_for_type(m) do
    case m do
      v when v in ["text", :text] -> LiveViewGrid.Components.TextFilter
      v when v in ["date", :date] -> LiveViewGrid.Components.DateFilter
      v when v in ["number", :number] -> LiveViewGrid.Components.NumberFilter
    end
  end

  def handle_event(
        "show_filter",
        %{"field_name" => field_name, "data_type" => data_type} = _params,
        socket
      ) do
    {send_update(get_filter_component_for_type(data_type), id: field_name, visible: true)}
    {:noreply, socket}
  end

  attr :id, :string, required: true, doc: "the element ID"

  attr :cols, :list,
    required: true,
    doc:
      "an array of tuples where the first element is the attribute name and the second element is the column name"

  attr :data, :list, required: true, doc: "a list of maps where every map is a row"

  attr :order_by, :map,
    required: false,
    default: OrdMap.new(%{booking_date: -1}),
    examples: [%{"my_field" => 1, "my_other_filed" => -1}],
    doc:
      "a map where the keys are the attribute names and the values are `1` for sorting in ascending order and `-1` for descending"

  attr :filter_by, :map,
    required: false,
    default: %{},
    doc: "a map where the keys are the attribute names and the values are strings to filter by",
    examples: [%{"my_field" => "abc"}]

  def render(assigns) do
    ~H"""
    <div>
      <div class="h-[90vh] max-h-[90vh] draggable-table-root block flow-root w-full w-fit overflow-auto text-sm">
        <div>
          <div id="table" class="inline-flex bg-white p-2.5" phx-hook="Draggable" id={@id}>
            <%= for %LiveViewGrid.Column{field: col_attr, header: col_name, data_type: data_type, formatter: formatter, filter: filter} <- @cols do %>
              <div class="sortable-table-column" x-data={"{#{col_attr}_open: false}"}>
                <div class="sticky top-0 z-10 bg-white bg-opacity-75">
                  <div
                    phx-click="update-sort"
                    phx-value-column={col_attr}
                    class="draggable-table-header break-keep flex h-9 justify-between gap-4 whitespace-nowrap border-b border-gray-300 px-3 py-2 text-left text-sm font-semibold text-gray-900 backdrop-blur backdrop-filter"
                  >
                    <p class="draggable-column-header-title"><%= col_name %></p>
                    <%= if String.to_atom(col_attr) in OrdMap.keys(@order_by) do %>
                      <%= if OrdMap.get(@order_by, String.to_existing_atom(col_attr))==1 do %>
                        <span class="material-symbols-outlined">
                          arrow_upward_alt
                        </span>
                      <% else %>
                        <span class="material-symbols-outlined">
                          arrow_downward_alt
                        </span>
                      <% end %>
                      <p>
                        <%= 1 +
                          (@order_by
                           |> OrdMap.keys()
                           |> Enum.find_index(&(&1 == String.to_existing_atom(col_attr)))) %>
                      </p>
                    <% end %>
                    <div>
                      <span
                        class={[
                          "material-symbols-outlined text-sm hover:cursor-pointer",
                          if(filter.enabled, do: "text-sky-500", else: "")
                        ]}
                        phx-click="show_filter"
                        phx-target={@myself}
                        phx-value-field_name={"filter_#{col_attr}"}
                        phx-value-data_type={data_type}
                      >
                        filter_alt
                      </span>
                      <span class="material-symbols-outlined drag-handle text-sm hover:cursor-grab">
                        menu
                      </span>
                    </div>
                  </div>

                  <.live_component
                    module={get_filter_component_for_type(data_type)}
                    column_name={col_name}
                    field_name={col_attr}
                    id={"filter_#{col_attr}"}
                    parent={self()}
                  />
                </div>

                <%= for {row, i} <- @data |> Enum.with_index() do %>
                  <div
                    data-row-index={i}
                    class="sortable-table-cell h-[1.8rem] flex-1 cursor-pointer whitespace-nowrap border-b border-gray-200 bg-white px-3 py-1 text-sm text-gray-500"
                  >
                    <%= Map.get(row, col_attr) |> formatter.(row) %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <.live_component
        module={LiveViewGrid.Paginator}
        id={"#{@socket.id}-paginator"}
        current_page={Map.get(assigns, :current_page, 1)}
        pages={Map.get(assigns, :total_pages, 1)}
        prefix={Map.get(assigns, :prefix)}
        total={Map.get(assigns, :total_rows, 1)}
      />
    </div>
    """
  end
end
