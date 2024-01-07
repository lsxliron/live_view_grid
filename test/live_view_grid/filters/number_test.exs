defmodule LiveViewGrid.Filters.NumberTest do
  use ExUnit.Case, async: true
  alias LiveViewGrid.Filters

  doctest LiveViewGrid.Filters.Number, import: true

  @field_name "test_filed"
  @test_value "100"

  describe "LiveViewGrid.Filters.Number" do
    test "return proper query for greater" do
      assert Filters.Number.get_subquery("greater", @test_value, @field_name) == %{
               @field_name => %{:"$gt" => 100}
             }
    end

    test "return proper query for greater or equal" do
      assert Filters.Number.get_subquery("greater_equal", @test_value, @field_name) == %{
               @field_name => %{:"$gte" => 100}
             }
    end

    test "return proper query for less" do
      assert Filters.Number.get_subquery("less", @test_value, @field_name) == %{
               @field_name => %{:"$lt" => 100}
             }
    end

    test "return proper query for less or equal" do
      assert Filters.Number.get_subquery("less_equal", @test_value, @field_name) == %{
               @field_name => %{:"$lte" => 100}
             }
    end

    test "return proper query for equal" do
      assert Filters.Number.get_subquery("equals", @test_value, @field_name) == %{
               @field_name => %{:"$eq" => 100}
             }
    end

    test "return proper query for not equal" do
      assert Filters.Number.get_subquery("not_equals", @test_value, @field_name) == %{
               @field_name => %{:"$ne" => 100}
             }
    end

    test "return proper query for not blank" do
      assert Filters.Number.get_subquery("not_blank", @test_value, @field_name) == %{
               "$and": [
                 %{@field_name => %{:"$exists" => true}},
                 %{@field_name => %{:"$ne" => nil}}
               ]
             }
    end

    test "return proper query for blank" do
      assert Filters.Number.get_subquery("blank", @test_value, @field_name) == %{
               "$or": [
                 %{@field_name => %{:"$exists" => false}},
                 %{@field_name => %{:"$eq" => nil}}
               ]
             }
    end

    test "can get a query with a single filter" do
      filter = %Filters.Number{filter_value_1: @test_value, enabled: true}

      assert Filters.Number.get_query(filter, @field_name) == %{
               @field_name => %{:"$gt" => 100}
             }
    end

    test "can get a query with a complex and filter" do
      filter = %Filters.Number{
        filter_value_1: @test_value,
        filter_type_2: "less",
        filter_value_2: "500",
        enabled: true
      }

      assert Filters.Number.get_query(filter, @field_name) == %{
               "$and": [
                 %{@field_name => %{:"$gt" => 100}},
                 %{@field_name => %{:"$lt" => 500}}
               ]
             }
    end

    test "can get a query with a complex or filter" do
      filter = %Filters.Number{
        filter_value_1: @test_value,
        filter_type_2: "less",
        filter_value_2: "500",
        enabled: true,
        combinator: "or"
      }

      assert Filters.Number.get_query(filter, @field_name) == %{
               "$or": [
                 %{@field_name => %{:"$gt" => 100}},
                 %{@field_name => %{:"$lt" => 500}}
               ]
             }
    end

    test "disabled filter returns no query" do
      refute %Filters.Number{
               enabled: false
             }
             |> Filters.Number.get_query(@test_value)
    end
  end
end
