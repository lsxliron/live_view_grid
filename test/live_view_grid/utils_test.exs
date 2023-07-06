defmodule LiveViewGrid.UtilsTest do
  use ExUnit.Case, async: true
  doctest LiveViewGrid.Utils, import: true
  import Phoenix.Component, only: [assign: 3]

  @cols [
    {"a", "A"},
    {"b", "B"},
    {"c", "C"},
    {"d", "D"}
  ]

  defp get_socket() do
    %Phoenix.LiveView.Socket{}
    |> assign(:prefix, "/dummy")
    |> LiveViewGrid.Utils.init_grid(@cols)
  end

  defp get_host_uri(), do: %URI{scheme: "http", host: "localhost", port: nil}

  describe "get_total_pages/1" do
    test "pagination object does not exist" do
      assert LiveViewGrid.Utils.get_total_pages(%{"pagination" => []}) == 1
    end

    test "pagination object exists" do
      assert LiveViewGrid.Utils.get_total_pages(%{"pagination" => [%{"total_pages" => 5}]}) == 5
    end
  end

  describe "get_total_rows/1" do
    test "dataset has no rows" do
      assert LiveViewGrid.Utils.get_total_rows(%{"pagination" => []}) == 0
    end

    test "pagination object exists" do
      assert LiveViewGrid.Utils.get_total_rows(%{"pagination" => [%{"total" => 5}]}) == 5
    end
  end

  describe "initializing grid properly" do
    test "initializing with defaults" do
      socket = get_socket()
      assert socket.assigns.cols == @cols
      assert socket.assigns.current_page == 1
      assert socket.assigns.filter_by == %{}
      assert socket.assigns.order_by == OrdMap.new(%{})
      assert socket.assigns.per_page == 100
      assert socket.assigns.total_pages == 1
      assert socket.assigns.total_rows == 1

      assert socket.assigns.cols_cache == %{
               "A" => "a",
               "B" => "b",
               "C" => "c",
               "D" => "d"
             }
    end

    test "initializing with custom values" do
      socket =
        get_socket()
        |> assign(:current_page, 5)
        |> assign(:total_pages, 500)
        |> assign(:total_rows, 5000)

      assert socket.assigns.current_page == 5
      assert socket.assigns.total_pages == 500
      assert socket.assigns.total_rows == 5000
    end
  end

  test "can set columns properly" do
    socket = get_socket()

    {:noreply, socket} =
      LiveViewGrid.Utils.set_columns(%{"columns" => ["D", "C", "B", "A"]}, socket)

    assert socket.assigns.cols == Enum.reverse(@cols)
  end

  test "can update filters properly" do
    socket = get_socket()

    params = %{"_target" => "dummy", "a" => "aaa", "b" => "bbb", "c" => "  "}
    {:noreply, socket} = LiveViewGrid.Utils.filter(params, socket)
    assert socket.redirected == {:live, :patch, %{kind: :push, to: "/dummy/?page=1"}}
    assert socket.assigns.filter_by == %{"a" => "aaa", "b" => "bbb"}
  end

  describe "paginate/2" do
    test "can paginate when there is not data" do
      get_data = fn _page, _socket -> {[], 0, 1} end
      socket = get_socket() |> assign(:get_data, get_data) |> LiveViewGrid.Utils.paginate(1)
      assert socket.assigns.total_pages == 1
      assert socket.assigns.data == []
      assert socket.assigns.total_rows == 0
    end

    test "shows an error when paginating to page that does not exist" do
      get_data = fn _page, _socket -> {[], 0, 1} end

      socket =
        get_socket()
        |> assign(:current_page, 0)
        # A way around :flash is a reserved assign by LiveView and it cannot be set
        # directly. Use the appropriate flash functions instead
        |> update_in([Access.key(:assigns), Access.key(:flash)], fn _ -> %{} end)
        |> assign(:get_data, get_data)
        |> LiveViewGrid.Utils.paginate(0)

      assert socket.assigns.total_pages == 1
      assert socket.assigns.data == []
      assert socket.assigns.total_rows == 0
      assert socket.redirected == {:live, :patch, %{kind: :push, to: "/dummy/?page=1"}}
      assert socket.assigns.flash == %{"error" => "0 is not a valid page"}
    end

    test "shows an error when paginating to page that exceeds the data count" do
      get_data = fn _page, _socket -> {[], 0, 5} end

      socket =
        get_socket()
        |> assign(:current_page, 10)
        # A way around :flash is a reserved assign by LiveView and it cannot be set
        # directly. Use the appropriate flash functions instead
        |> update_in([Access.key(:assigns), Access.key(:flash)], fn _ -> %{} end)
        |> assign(:get_data, get_data)
        |> LiveViewGrid.Utils.paginate(0)

      assert socket.assigns.total_pages == 5
      assert socket.assigns.data == []
      assert socket.assigns.total_rows == 0
      assert socket.redirected == {:live, :patch, %{kind: :push, to: "/dummy/?page=5"}}
      assert socket.assigns.flash == %{"error" => "10 is not a valid page"}
    end
  end

  describe "handle_params/2" do
    test "no-op if socket is not connected" do
      socket = get_socket()
      assert {:noreply, socket} == LiveViewGrid.Utils.handle_params(%{}, "/", socket)
    end

    test "adding page as URL param if not provided" do
      socket =
        get_socket()
        |> Map.put(:transport_pid, IEx.Helpers.pid(0, 0, 0))
        |> Map.put(:host_uri, get_host_uri())

      {:noreply, socket} = LiveViewGrid.Utils.handle_params(%{}, "/", socket)
      assert socket.redirected == {:live, :patch, %{kind: :push, to: "/?page=1"}}
      assert Map.get(socket.assigns, :flash) |> is_nil()
    end

    test "redirecting to the first page if page is invalid" do
      socket =
        get_socket()
        |> update_in([Access.key(:assigns), Access.key(:flash)], fn _ -> %{} end)
        |> Map.put(:transport_pid, IEx.Helpers.pid(0, 0, 0))
        |> Map.put(:host_uri, get_host_uri())

      {:noreply, socket} = LiveViewGrid.Utils.handle_params(%{"page" => "abc"}, "/", socket)
      assert socket.redirected == {:live, :patch, %{kind: :push, to: "/?page=1"}}
      assert socket.assigns.flash == %{"error" => "abc is not a valid page number"}
    end

    test "redirecting to the proper page if page is invalid" do
      get_data = fn _page, _socket -> {[], 0, 5} end

      socket =
        get_socket()
        |> assign(:get_data, get_data)
        |> update_in([Access.key(:assigns), Access.key(:flash)], fn _ -> %{} end)
        |> Map.put(:transport_pid, IEx.Helpers.pid(0, 0, 0))
        |> Map.put(:host_uri, get_host_uri())

      {:noreply, socket} = LiveViewGrid.Utils.handle_params(%{"page" => "4"}, "/", socket)
      assert Map.get(socket.assigns, :flash) == %{}
    end
  end

  test "can properly update the sort order of columns" do
    get_data = fn _page, _socket -> {[], 0, 5} end

    socket =
      get_socket()
      |> assign(:get_data, get_data)

    assert socket.assigns.order_by == OrdMap.new()
    {:noreply, socket} = LiveViewGrid.Utils.update_sort(%{"column" => "a"}, socket)
    assert socket.assigns.order_by == OrdMap.new(%{a: 1})

    {:noreply, socket} = LiveViewGrid.Utils.update_sort(%{"column" => "a"}, socket)
    assert socket.assigns.order_by == OrdMap.new(%{a: -1})

    {:noreply, socket} = LiveViewGrid.Utils.update_sort(%{"column" => "b"}, socket)
    assert socket.assigns.order_by == OrdMap.new(%{a: -1, b: 1})

    {:noreply, socket} = LiveViewGrid.Utils.update_sort(%{"column" => "a"}, socket)
    assert socket.assigns.order_by == OrdMap.new(%{b: 1})
  end
end
