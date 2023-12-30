defmodule LiveViewGridWeb.Behaviours.BaseFilter do
  @callback get_options() :: keyword()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      require Logger

      @default_filter_type Keyword.fetch!(opts, :default_filter_type)
      @filter_type Keyword.fetch!(opts, :filter_type)

      @impl Phoenix.LiveComponent
      def mount(socket) do
        {:ok,
         socket
         |> assign(:input_type, Atom.to_string(@filter_type))
         |> assign(:filter_value_1, "")
         |> assign(:filter_type_1, @default_filter_type)
         |> assign(:filter_value_2, "")
         |> assign(:filter_type_2, @default_filter_type)
         |> assign(:combinator, "and")
         |> assign(:options, get_options())
         |> assign(:visible, false)}
      end

      # TODO: put in utils
      def get_filter_module(:text) do
        LiveViewGrid.Filters.Text
      end

      def get_filter_module(:number) do
        LiveViewGrid.Filters.Number
      end

      def get_filter_module(:date) do
        LiveViewGrid.Filters.Date
      end

      @impl Phoenix.LiveComponent
      def handle_event("change", params, socket) do
        filter_value_1 = params |> Map.get("filter_value_1", socket.assigns.filter_value_1)
        filter_value_2 = params |> Map.get("filter_value_2", socket.assigns.filter_value_2)
        filter_type_1 = params |> Map.get("filter_type_1", socket.assigns.filter_type_1)
        filter_type_2 = params |> Map.get("filter_type_2", socket.assigns.filter_type_2)
        combinator = params |> Map.get("combinator", socket.assigns.combinator)
        enabled = String.trim(filter_value_1) != "" or filter_type_1 in ["not_blank", "blank"]

        filter_params = %{
          filter_value_1: filter_value_1,
          filter_type_1: filter_type_1,
          filter_value_2: filter_value_2,
          filter_type_2: filter_type_2,
          enabled: enabled,
          combinator: combinator
        }

        filter = @filter_type |> get_filter_module() |> struct(filter_params)

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

      @impl Phoenix.LiveComponent
      def handle_event("hide_filter", _params, socket) do
        {:noreply, socket |> assign(:visible, false)}
      end

      def update_filter_in_coldef(socket, filter) do
        send(socket.assigns.parent, {:update_filter, socket.assigns.field_name, filter})
        socket
      end

      quote do
        attr :column_name, :string, required: true
        attr :field_name, :string, required: true
      end

      @impl Phoenix.LiveComponent
      def render(var!(assigns)) do
        ~H"""
        <form class="relative block h-2" phx-change="change" phx-target={@myself}>
          <%= if @visible do %>
            <div class="w-full min-w-36 absolute z-10 m-2 m-8 -translate-y-8 rounded-md border border-black bg-white p-2 p-2 text-center shadow-lg">
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
                type={@input_type}
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
                  type={@input_type}
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
  end
end
