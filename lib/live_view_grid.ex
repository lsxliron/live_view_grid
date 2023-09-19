defmodule LiveViewGrid do
  use Phoenix.LiveComponent
  require Logger

  @moduledoc """
  A tabular grid to render data
  """

  attr(:id, :string, required: true, doc: "the element ID")

  attr(:cols, :list,
    required: true,
    doc:
      "an array of tuples where the first element is the attribute name and the second element is the column name"
  )

  attr(:data, :list, required: true, doc: "a list of maps where every map is a row")

  attr(:order_by, :map,
    required: false,
    default: OrdMap.new(%{booking_date: -1}),
    examples: [%{"my_field" => 1, "my_other_filed" => -1}],
    doc:
      "a map where the keys are the attribute names and the values are `1` for sorting in ascending order and `-1` for descending"
  )

  attr(:filter_by, :map,
    required: false,
    default: %{},
    doc: "a map where the keys are the attribute names and the values are strings to filter by",
    examples: [%{"my_field" => "abc"}]
  )

  def render(assigns) do
    ~H"""
    <div>
      <div class="h-[90vh] max-h-[90vh] block flow-root w-full w-fit overflow-auto text-sm draggable-table-root">
        <form phx-change="filter">
          <div id="table" class="inline-flex bg-white p-2.5" phx-hook="Draggable" id={@id}>
            <%= for {col_attr, col_name} <- @cols do %>
              <div class="sortable-table-column">
                <div class="sticky top-0 z-10 bg-white bg-opacity-75">
                  <div phx-click="update-sort"
                      phx-value-column={col_attr}
                      class="draggable-table-header break-keep whitespace-nowrap border-b border-gray-300 px-3 py-2 text-left text-sm font-semibold text-gray-900 backdrop-blur backdrop-filter justify-between flex gap-4 h-9">
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
                    <span class="material-symbols-outlined drag-handle text-sm hover:cursor-grab">
                      menu
                    </span>
                  </div>


                  <input
                    class="border-1 w-full rounded-md border-stone-200 text-xs outline-none outline-none ring-0 focus:border-none focus:outline-none focus:ring-2 focus:ring-indigo-600"
                    type="text"
                    phx-value-column={col_attr}
                    phx-debounce="300"
                    value={Map.get(@filter_by, col_attr, "")}
                    name={col_attr}
                  />

                </div>

                <%= for {row, i} <- @data |> Enum.with_index() do %>
                  <div data-row-index={i}
                       class={"sortable-table-cell bg-white flex-1 whitespace-nowrap border-b border-gray-200 px-3 py-1 text-sm text-gray-500 h-[1.8rem] cursor-pointer"}
                    ><%= Map.get(row, col_attr) %></div>
                <% end %>
              </div>
            <% end %>
          </div>
        </form>
      </div>


      <.live_component module={LiveViewGrid.Paginator}
                       id={"#{@socket.id}-paginator"}
                       current_page={Map.get(assigns, :current_page, 1)}
                       pages={Map.get(assigns, :total_pages, 1)}
                       prefix={Map.get(assigns, :prefix)}
                       total={Map.get(assigns, :total_rows, 1)} />
    </div>
    """
  end
end
