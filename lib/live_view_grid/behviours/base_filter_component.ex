defmodule LiveViewGrid.Behaviours.BaseFilterComponent do
  @callback get_options(map) :: keyword()
  @callback on_change(
              Phoenix.LiveView.unsigned_params(),
              atom(),
              String.t(),
              Phoenix.LiveView.Socket.t()
            ) :: map()
  @callback on_clear(
              Phoenix.LiveView.unsigned_params(),
              atom(),
              String.t(),
              Phoenix.LiveView.Socket.t()
            ) :: map()

  @type filter_params ::
          LiveViewGrid.Filters.Text.filter_params()
          | LiveViewGrid.Filters.Number.filter_params()
          | LiveViewGrid.Filters.Date.filter_params()

  @type filter ::
          LiveViewGrid.Filters.Text.t()
          | LiveViewGrid.Filters.Number.t()
          | LiveViewGrid.Filters.Date.t()

  @doc """
  A default implementation for the `on_change` callback which is being fired every time a filter is changed

  ## Parameters
  - `params` - the LiveView params
  - `filter_type` - the affected filter type, can be one of `:date`, `:number` or `:text`
  - `default_filter_type` the default selection of the filter dropdown (all options should be specified in the `get_options/0` callback)
  - `socket` - the LiveView socket
  """
  @spec default_on_change(
          Phoenix.LiveView.unsigned_params(),
          LiveViewGrid.Column.data_type(),
          String.t(),
          Phoenix.LiveView.Socket.t()
        ) :: filter_params()
  def default_on_change(params, _filter_type, _default_filter_type, socket) do
    filter_value_1 = params |> Map.get("filter_value_1", socket.assigns.filter_value_1)
    filter_value_2 = params |> Map.get("filter_value_2", socket.assigns.filter_value_2)
    filter_type_1 = params |> Map.get("filter_type_1", socket.assigns.filter_type_1)
    filter_type_2 = params |> Map.get("filter_type_2", socket.assigns.filter_type_2)
    combinator = params |> Map.get("combinator", socket.assigns.combinator)
    enabled = String.trim(filter_value_1) != "" or filter_type_1 in ["not_blank", "blank"]

    %{
      filter_value_1: filter_value_1,
      filter_type_1: filter_type_1,
      filter_value_2: filter_value_2,
      filter_type_2: filter_type_2,
      enabled: enabled,
      combinator: combinator
    }
  end

  @doc """
  A default implementation for the `on_change` callback which is being fired every time a filter is cleared

  ## Parameters
  - `params` - the LiveView params
  - `filter_type` - the affected filter type, can be one of `:date`, `:number` or `:text`
  - `default_filter_type` the default selection of the filter dropdown (all options should be specified in the `get_options/0` callback)
  - `socket` - the LiveView socket
  """
  @spec default_on_clear(
          Phoenix.LiveView.unsigned_params(),
          LiveViewGrid.Column.data_type(),
          String.t(),
          Phoenix.LiveView.Socket.t()
        ) :: filter_params()

  def default_on_clear(_params, _filter_type, default_filter_type, _socket) do
    %{
      filter_value_1: "",
      filter_type_1: default_filter_type,
      filter_value_2: "",
      filter_type_2: default_filter_type,
      enabled: false,
      combinator: "and"
    }
  end

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

      @doc false
      def on_change(params, socket) do
        # a helper function to make it possible to override the default implementation of on_change
        LiveViewGrid.Behaviours.BaseFilterComponent.default_on_change(
          params,
          @filter_type,
          @default_filter_type,
          socket
        )
      end

      defoverridable on_change: 2

      @doc false
      def on_clear(params, socket) do
        # a helper function to make it possible to override the default implementation of on_clear
        LiveViewGrid.Behaviours.BaseFilterComponent.default_on_clear(
          params,
          @filter_type,
          @default_filter_type,
          socket
        )
      end

      defoverridable on_clear: 2

      @impl Phoenix.LiveComponent
      def handle_event("change", params, socket) do
        # fires every time the filter value is changed
        filter_params = on_change(params, socket)
        filter = @filter_type |> LiveViewGrid.Utils.get_filter_module() |> struct(filter_params)
        Process.send_after(socket.assigns.parent, :perform_filter, 500)
        {:noreply, socket |> update_filter_in_column(filter) |> assign(filter_params)}
      end

      @impl Phoenix.LiveComponent
      def handle_event("hide_filter", _params, socket) do
        # fires every time the filter is closed
        {:noreply, socket |> assign(:visible, false)}
      end

      @impl Phoenix.LiveComponent
      def handle_event("clear_filter", params, socket) do
        # fires every time the filter is cleared
        filter_params = on_clear(socket, params)

        filter = @filter_type |> LiveViewGrid.Utils.get_filter_module() |> struct(filter_params)
        Process.send_after(socket.assigns.parent, :perform_filter, 100)

        {:noreply, socket |> update_filter_in_column(filter) |> assign(filter_params)}
      end

      @doc """
      Updates the filter in the parent LiveView socket

      ## Parameters
      `socket` - the LiveView socket
      `filter` - the new filter struct to update
      """
      @spec update_filter_in_column(Phoenix.LiveView.Socket.t(), LiveViewGrid.Behaviours.BaseFilterComponent.filter()) ::
              Phoenix.LiveView.Socket.t()
      def update_filter_in_column(socket, filter) do
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
            <div class="min-w-36 absolute z-10 m-2 m-8 w-full -translate-y-8 rounded-md border border-black bg-white p-2 p-2 text-center shadow-lg">
              <div class="flex items-baseline justify-between">
                <p class="tex-sm mb-2 text-black">Filters for <%= @column_name %></p>
                <button type="button" phx-click="clear_filter" phx-target={@myself}>
                  <span class="material-symbols-outlined text-xs hover:text-black/80">
                    restart_alt
                  </span>
                </button>
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
