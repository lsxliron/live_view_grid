defmodule LiveViewGridTest do
  use LiveViewGrid.GridCase

  describe "LiveViewGrid" do
    test "grid initialized properly", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, LiveViewGrid.TestGrid)

      # Columns are rendered properly
      assert view |> element("p.draggable-column-header-title", "Text") |> has_element?
      assert view |> element("p.draggable-column-header-title", "Number") |> has_element?
      assert view |> element("p.draggable-column-header-title", "Date") |> has_element?

      # Content is rendered properly
      assert view |> element("div.sortable-table-cell", "abc") |> has_element?
      assert view |> element("div.sortable-table-cell", "2024-01-10T00:00:00Z") |> has_element?
      assert view |> element("div.sortable-table-cell", "100") |> has_element?

      # Filter buttons are present
      assert view
             |> element(~s/span[phx-value-field_name="filter_text"]/, "filter_alt")
             |> has_element?

      assert view
             |> element(~s/span[phx-value-field_name="filter_number"]/, "filter_alt")
             |> has_element?

      assert view
             |> element(~s/span[phx-value-field_name="filter_date"]/, "filter_alt")
             |> has_element?
    end

    test "opens a filter box when the button is clicked", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, LiveViewGrid.TestGrid)

      view
      |> element(~s/span[phx-value-field_name="filter_text"]/, "filter_alt")
      |> render_click()

      assert view |> element(~s/select[name="filter_type_1"]/) |> has_element?()
    end

    test "shows the second part of the filter when the first is full", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, LiveViewGrid.TestGrid)

      refute view |> element(~s/input[name="filter_value_2"]/) |> has_element?()
      refute view |> element("#text_and") |> has_element?()
      refute view |> element("#text_or") |> has_element?()

      # open filter
      view
      |> element(~s/span[phx-value-field_name="filter_text"]/, "filter_alt")
      |> render_click()

      # type text in the first part
      view
      |> element(~s/div[phx-value-column="text"]~form/)
      |> render_change(%{"filter_value_1" => "abc"})

      assert view |> element(~s/input[name="filter_value_2"]/) |> has_element?()
      assert view |> element(~s/#text_and[checked="checked"]/) |> has_element?()
      assert view |> element("#text_or") |> has_element?()
    end

    test "when blank is chosen, the filter is disabled", %{conn: conn} do
      {:ok, view, _html} = live_isolated(conn, LiveViewGrid.TestGrid)

      # open filter
      view
      |> element(~s/span[phx-value-field_name="filter_text"]/, "filter_alt")
      |> render_click()

      # Check that input is not disabled
      assert view |> element(~s/input[name="filter_value_1"]/) |> has_element?()

      refute view
             |> element(~s/input[name="filter_value_1"][disabled="disabled"]/)
             |> has_element?()

      view
      |> element(~s/div[phx-value-column="text"]~form/)
      |> render_change(%{"filter_type_1" => "blank"})

      # Ensure input is disabled
      assert view
             |> element(~s/input[name="filter_value_1"][disabled="disabled"]/)
             |> has_element?()
    end
  end
end
