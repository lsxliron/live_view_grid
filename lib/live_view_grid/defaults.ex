defmodule LiveViewGrid.Defaults do
  @moduledoc """
  This module contains the default implementations of the Grid component required callbacks
  """
  defmacro __using__(_opts) do
    quote do
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
    end
  end
end
