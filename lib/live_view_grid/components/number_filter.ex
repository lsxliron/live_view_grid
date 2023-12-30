defmodule LiveViewGrid.Components.NumberFilter do
  use Phoenix.LiveComponent
  require Logger

  def mount(socket) do
    options = [
      "Greater Than": "greater",
      "Greater Than Eq.": "greater_equal",
      "Less Than": "less",
      "Less Than Eq.": "less_equal",
      Equals: "equals",
      "Not Equals": "not_equals",
      Blank: "blank",
      "Not Blank": "not_blank"
    ]

    {:ok,
     socket
     |> assign(:filter_value_1, "")
     |> assign(:filter_type_1, "greater")
     |> assign(:filter_value_2, "")
     |> assign(:filter_type_2, "greater")
     |> assign(:combinator, "and")
     |> assign(:options, options)
     |> assign(:visible, false)}
  end

  def handle_event("change", params, socket) do
    filter_value_1 = params |> Map.get("filter_value_1", socket.assigns.filter_value_1)
    filter_value_2 = params |> Map.get("filter_value_2", socket.assigns.filter_value_2)
    filter_type_1 = params |> Map.get("filter_type_1", socket.assigns.filter_type_1)
    filter_type_2 = params |> Map.get("filter_type_2", socket.assigns.filter_type_2)
    combinator = params |> Map.get("combinator", socket.assigns.combinator)
    enabled = String.trim(filter_value_1) != "" or filter_type_1 in ["not_blank", "blank"]

    filter = %LiveViewGrid.Filters.Number{
      filter_value_1: filter_value_1,
      filter_type_1: filter_type_1,
      filter_value_2: filter_value_2,
      filter_type_2: filter_type_2,
      enabled: enabled,
      combinator: combinator
    }

    Process.send_after(socket.assigns.parent, :perform_filter, 500)

    {:noreply,
     socket
     |> update_filter_in_coldef(filter)
     |> assign(:filter_value_1, filter_value_1)
     |> assign(:filter_type_1, filter_type_1)
     |> assign(:filter_value_2, filter_value_2)
     |> assign(:filter_type_2, filter_type_2)
     |> assign(:combinator, combinator)
     |> assign(:enabled, enabled)}
  end

  def handle_event("hide_filter", _params, socket) do
    {:noreply, socket |> assign(:visible, false)}
  end

  def update_filter_in_coldef(socket, filter) do
    send(socket.assigns.parent, {:update_filter, socket.assigns.field_name, filter})
    socket
  end

  attr :column_name, :string, required: true
  attr :field_name, :string, required: true

  def render(assigns) do
    ~H"""
    <form class="relative block h-2" phx-change="change" phx-target={@myself}>
      <%= if @visible do %>
        <div class="min-w-48 absolute z-10 m-2 m-8 -translate-y-8 rounded-md border border-black bg-white p-2 p-2 text-center shadow-lg">
          <div class="flex items-baseline justify-between">
            <p class="tex-sm mb-2 text-black">Filters for <%= @column_name %></p>
            <button type="button" phx-click="hide_filter" phx-target={@myself}>
              <span class="material-symbols-outlined text-xs hover:text-black/80">
                close
              </span>
            </button>
          </div>
          <select class="mb-1 w-full rounded-md p-1 text-xs" name="filter_type_1">
            <%= Phoenix.HTML.Form.options_for_select(@options, @filter_type_1) %>
          </select>
          <input type="hidden" name="field_name" value={@field_name} />
          <input
            type="number"
            class="border-1 mb-1 w-full rounded-md border-stone-200 p-1 text-xs outline-none outline-none ring-0 focus:border-none focus:outline-none focus:ring-2 focus:ring-indigo-600 disabled:bg-gray-200"
            phx-debounce="300"
            name="filter_value_1"
            disabled={@filter_type_1 in ["not_blank", "blank"]}
            value={@filter_value_1}
          />

          <%= if not is_nil(@filter_value_1) and String.trim(@filter_value_1) != "" do %>
            <div class="mb-1 flex justify-center gap-4">
              <div>
                <input
                  type="radio"
                  name="combinator"
                  value="and"
                  id={"#{@field_name}_and"}
                  checked={@combinator == "and"}
                />
                <label for={"#{@field_name}_and"}>AND</label>
              </div>
              <div>
                <input
                  type="radio"
                  name="combinator"
                  value="or"
                  id={"#{@field_name}_or"}
                  checked={@combinator == "or"}
                />
                <label for={"#{@field_name}_or"}>OR</label>
              </div>
            </div>
            <select class="mb-1 w-full rounded-md p-1 text-xs" name="filter_type_2">
              <%= Phoenix.HTML.Form.options_for_select(@options, @filter_type_2) %>
            </select>

            <input
              type="number"
              class="border-1 mb-1 w-full rounded-md border-stone-200 p-1 text-xs outline-none outline-none ring-0 focus:border-none focus:outline-none focus:ring-2 focus:ring-indigo-600 disabled:bg-gray-200"
              phx-debounce="300"
              name="filter_value_2"
              disabled={@filter_type_2 in ["not_blank", "blank"]}
              value={@filter_value_2}
            />
          <% end %>
        </div>
      <% end %>
    </form>
    """
  end
end
