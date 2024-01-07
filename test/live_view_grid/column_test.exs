defmodule LiveViewGrid.ColumnTest do
  use ExUnit.Case, async: true
  alias LiveViewGrid.Column

  def create_column(_) do
    col =
      %Column{
        field: "test_field",
        data_type: :text
      }
      |> Column.init()

    {:ok, %{col: col}}
  end

  setup [:create_column]

  describe "LiveViewGrid.Column" do
    test "can initialize properly", %{col: col} do
      assert col.header == "Test Field"
      refute col.formatter |> is_nil()
      refute col.filter |> is_nil()
      refute col.disable_filter
    end

    test "can initialize with custom header and not filter" do
      c =
        %Column{
          field: "other_test_field",
          header: "Test Field",
          data_type: :text
        }
        |> Column.init()

      assert c.header == "Test Field"
    end

    test "initializes proper filter for text data type", %{col: col} do
      %text_filter{} = col.filter
      assert text_filter == LiveViewGrid.Filters.Text
    end

    test "initializes proper filter for number data type" do
      col =
        %Column{
          field: "test_field",
          data_type: :number
        }
        |> Column.init()

      %text_filter{} = col.filter
      assert text_filter == LiveViewGrid.Filters.Number
    end

    test "initializes proper filter for date data type" do
      col =
        %Column{
          field: "test_field",
          data_type: :date
        }
        |> Column.init()

      %text_filter{} = col.filter
      assert text_filter == LiveViewGrid.Filters.Date
    end

    test "has an identity formatter when one not provided", %{col: col} do
      col.formatter.("value", %{}) == "value"
    end

    test "has an custom formatter" do
      formatter = fn v, _ -> "!#{v}!" end

      col =
        %Column{
          field: "test_field",
          data_type: :text,
          formatter: formatter
        }
        |> Column.init()

      col.formatter.("value", %{}) == "!value!"
    end
  end
end
