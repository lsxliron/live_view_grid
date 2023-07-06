defmodule LiveViewGrid.Paginator do
  use Phoenix.LiveComponent

  @moduledoc """
  A paginator for a grid. Shows the total number of items, current page, total pages
  and provides links for the pages

  ## Example
  ```
  <Paginator total={100} current_page={1} pages={10} />
  ```
  """

  @doc """
  Returns the page numbers that should be included in the paginator.

  ## Parameters
  - `assigns` - the assigns map that is passed to the component. The map should include
     the following keys:
     - `pages` - the total number of pages
     - `current_page` - the current page

  ## Example

  ```
  iex> get_pages(%{pages: 1, current_page: 1})
  1..1
  iex> get_pages(%{pages: 3, current_page: 1})
  1..3
  iex> get_pages(%{pages: 10, current_page: 9})
  6..10
  iex> get_pages(%{pages: 10, current_page: 5})
  3..7
  ```
  """
  @spec get_pages(map()) :: Range.t()
  def get_pages(assigns) do
    cond do
      assigns.pages < 2 ->
        1..1
      assigns.current_page < 4 ->
        1..min(assigns.pages, 5)

      assigns.pages - 3 < assigns.current_page ->
        (max(1,assigns.pages - 4))..assigns.pages

      true ->
        a = assigns.current_page - 2
        b = min(assigns.pages, assigns.current_page + 2)
        a..b
    end
  end

  attr :total, :integer, required: true, doc: "the total number of records"
  attr :current_page, :integer, required: true, doc: "the current page"
  attr :pages, :integer, required: true, doc: "the total number of pages"

  def render(assigns) do
    ~H"""
    <div class="flex w-full justify-between gap-8 px-4 text-blue-600 font-semibold mt-4 text-lg">
      <div class="flex justify-center gap-8 flex-grow">
        <.link patch={"#{Map.get(assigns, :prefix, "/")}?page=#{1}"}>
          <span class="material-symbols-outlined">first_page</span>
        </.link>
        <%= for p <- get_pages(assigns) do %>
          <.link
            patch={"#{Map.get(assigns, :prefix, "/")}?page=#{p}"}
            class={if(@current_page == p, do: "font-bold", else: "font-normal")}
          >
            <%= p %>
          </.link>
        <% end %>
        <.link patch={"#{Map.get(assigns, :prefix, "/")}?page=#{@pages}"}>
          <span class="material-symbols-outlined">last_page</span>
        </.link>
      </div>
      <div class="flex-initial">
        <p><%= "Page #{@current_page}/#{@pages} (#{@total} rows)" %></p>
      </div>
    </div>
    """
  end
end
