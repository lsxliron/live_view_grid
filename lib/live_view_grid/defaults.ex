defmodule LiveViewGrid.Defaults do
  @moduledoc """
  This module contains the default implementations of the Grid component required callbacks
  """
  defmacro __using__(_opts) do
    quote do
      require Logger

      @impl Phoenix.LiveView
      def handle_event("set-columns", params, socket) do
        LiveViewGrid.Utils.set_columns(params, socket)
      end

      @impl Phoenix.LiveView
      def handle_event("filter", params, socket) do
        LiveViewGrid.Utils.filter(params, socket)
      end

      @impl Phoenix.LiveView
      def handle_event("update-sort", params, socket) do
        LiveViewGrid.Utils.update_sort(params, socket)
      end

      @impl Phoenix.LiveView
      def handle_params(params, uri, socket) do
        LiveViewGrid.Utils.handle_params(params, uri, socket)
      end

      @impl Phoenix.LiveView
      def handle_info(:perform_filter, socket) do
        LiveViewGrid.Utils.filter(%{}, socket)
      end

      @impl Phoenix.LiveView
      def handle_info({:update_filter, field_name, filter}, socket) do
        Logger.debug("updating filter for field #{field_name}")
        Logger.debug("new filter: #{inspect(filter)}")
        cols =
          socket.assigns.cols
          |> Enum.map(fn item ->
            if item.field == field_name do
              Map.put(item, :filter, filter)
            else
              item
            end
          end)

        {:noreply, socket |> assign(:cols, cols)}
      end
    end
  end
end
