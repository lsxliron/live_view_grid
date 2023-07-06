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
      <div class="h-[90vh] max-h-[90vh] block flow-root w-full w-fit overflow-auto text-sm">
        <form phx-change="filter">
          <table class="table w-full min-w-full divide-y divide-gray-300" phx-hook="Draggable" id={@id}>
            <thead class="sticky top-0 z-10 border-b border-gray-300 bg-white bg-opacity-75 px-3 py-2 text-left text-sm font-semibold text-gray-900 backdrop-blur backdrop-filter">
              <tr>
                <th :for={{col_attr, col_name} <- @cols}>
                  <div
                    class="flex items-center justify-between px-2"
                    phx-click="update-sort"
                    phx-value-column={col_attr}
                  >
                    <p class="table-header mr-4 flex grow items-center whitespace-nowrap text-sm hover:cursor-pointer">
                      <%= col_name %>
                      <div class="flex w-full justify-between px-4">
                        <%= if String.to_existing_atom(col_attr) in OrdMap.keys(@order_by) do %>
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
                      </div>
                    </p>
                    <p class="flex-initial">
                      <span class="material-symbols-outlined drag-handle text-sm hover:cursor-grab">
                        menu
                      </span>
                    </p>
                  </div>
                </th>
              </tr>

              <tr>
                <th class="px-1" :for={{col_attr, _col_name} <- @cols}>
                  <input
                    class="border-1 w-full rounded-md border-stone-200 text-xs outline-none outline-none ring-0 focus:border-none focus:outline-none focus:ring-2 focus:ring-indigo-600"
                    type="text"
                    phx-value-column={col_attr}
                    phx-debounce="300"
                    value={Map.get(@filter_by, col_attr, "")}
                    name={col_attr}
                  />
                </th>
              </tr>
            </thead>

            <tbody
              id={"#{@id}-body"}
              class="relative mt-12 divide-y divide-gray-200 overflow-y-auto bg-white"
            >
              <tr :for={d <- @data}>
                <%= for k <- Enum.map(@cols, &elem(&1, 0)) do %>
                  <td class="whitespace-nowrap border-b border-gray-200 px-3 py-1 text-sm text-gray-500 sm:table-cell">
                    <%= Map.get(d, k) %>
                  </td>
                <% end %>
              </tr>
            </tbody>
          </table>
        </form>
      </div>
      <.live_component module={LiveViewGrid.Paginator}
                       id={"#{@socket.id}-paginator"}
                       current_page={Map.get(assigns, :current_page, 1)}
                       pages={Map.get(assigns, :total_pages, 1)}
                       prefix={@prefix}
                       total={Map.get(assigns, :total_rows, 1)} />
    </div>
    """
  end
end
