defmodule LiveViewGrid.PaginatorTest do
  use ExUnit.Case, async: true
  doctest LiveViewGrid.Paginator, import: true
  import Phoenix.LiveViewTest

  test "renders properly with a single page" do
    html =
      render_component(LiveViewGrid.Paginator, id: "test", pages: 1, current_page: 1, total: 100)

    assert html =~ "span class=\"material-symbols-outlined\">first_page</span>"
    assert html =~ "<a href=\"/?page=1\""
    assert html =~ "<span class=\"material-symbols-outlined\">last_page</span>"
  end

  test "renders properly with no rows" do
    html =
      render_component(LiveViewGrid.Paginator, id: "test", pages: 1, current_page: 1, total: 0)

    assert html =~ "span class=\"material-symbols-outlined\">first_page</span>"
    assert html =~ "<a href=\"/?page=1\""
    assert html =~ "<span class=\"material-symbols-outlined\">last_page</span>"
  end

  test "renders properly with multiple pages" do
    html =
      render_component(LiveViewGrid.Paginator, id: "test", pages: 10, current_page: 1, total: 100)

    assert html =~ "span class=\"material-symbols-outlined\">first_page</span>"
    assert html =~ "<a href=\"/?page=1\""

    for i <- 2..5 do
      assert html =~ "<a href=\"/?page=#{i}\""
    end

    refute html =~ "<a href=\"/?page=6\""
    assert html =~ "<a href=\"/?page=10\""

    assert html =~ "<span class=\"material-symbols-outlined\">last_page</span>"
  end

  test "renders properly with multiple pages and user is on 5th page" do
    html =
      render_component(LiveViewGrid.Paginator, id: "test", pages: 10, current_page: 5, total: 100)

    assert html =~ "span class=\"material-symbols-outlined\">first_page</span>"
    assert html =~ "<a href=\"/?page=1\""
    refute html =~ "<a href=\"/?page=2\""

    for i <- 3..7 do
      assert html =~ "<a href=\"/?page=#{i}\""
    end

    refute html =~ "<a href=\"/?page=8\""
    assert html =~ "<a href=\"/?page=10\""

    assert html =~ "<span class=\"material-symbols-outlined\">last_page</span>"
  end
end
