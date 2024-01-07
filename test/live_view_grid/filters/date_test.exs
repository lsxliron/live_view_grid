defmodule LiveViewGrid.Filters.DateTest do
  use ExUnit.Case, async: true
  alias LiveViewGrid.Filters

  @field_name "test_filed"
  @test_value "2024-01-10"

  describe "LiveViewGrid.Filters.Date" do
    test "return proper query for after" do
      expected = %{@field_name => %{:"$gt" => ~U[2024-01-10T23:59:59Z]}}
      assert Filters.Date.get_subquery("after", @test_value, @field_name) == expected
    end

    test "return proper query for before" do
      expected = %{@field_name => %{:"$lt" => ~U[2024-01-10T00:00:00Z]}}
      assert Filters.Date.get_subquery("before", @test_value, @field_name) == expected
    end

    test "return proper query for equal" do
      expected = %{
        "$and": [
          %{@field_name => %{:"$gte" => ~U[2024-01-10T00:00:00Z]}},
          %{@field_name => %{:"$lte" => ~U[2024-01-10T23:59:59Z]}}
        ]
      }

      assert Filters.Date.get_subquery("equals", @test_value, @field_name) == expected
    end

    test "return proper query for not equal" do
      expected = %{
        "$or": [
          %{@field_name => %{:"$gt" => ~U[2024-01-10T23:59:59Z]}},
          %{@field_name => %{:"$lt" => ~U[2024-01-10T00:00:00Z]}}
        ]
      }

      assert Filters.Date.get_subquery("not_equals", @test_value, @field_name) == expected
    end

    test "return proper query for not blank" do
      expected = %{
        "$and": [
          %{@field_name => %{:"$exists" => true}},
          %{@field_name => %{:"$ne" => nil}}
        ]
      }

      assert Filters.Date.get_subquery("not_blank", @test_value, @field_name) == expected
    end

    test "return proper query for blank" do
      expected = %{
        "$or": [
          %{@field_name => %{:"$exists" => false}},
          %{@field_name => %{:"$eq" => nil}}
        ]
      }

      assert Filters.Date.get_subquery("blank", @test_value, @field_name) == expected
    end

    test "can get a query with a single filter" do
      filter = %Filters.Date{filter_value_1: @test_value, enabled: true}

      assert Filters.Date.get_query(filter, @field_name) == %{
               @field_name => %{:"$lt" => ~U[2024-01-10T00:00:00Z]}
             }
    end

    test "can get a query with a complex and filter" do
      filter = %Filters.Date{
        filter_value_1: @test_value,
        filter_type_2: "after",
        filter_value_2: "2024-01-01",
        enabled: true
      }

      assert Filters.Date.get_query(filter, @field_name) == %{
               "$and": [
                 %{@field_name => %{:"$lt" => ~U[2024-01-10T00:00:00Z]}},
                 %{@field_name => %{:"$gt" => ~U[2024-01-01T23:59:59Z]}}
               ]
             }
    end

    test "can get a query with a complex or filter" do
      filter = %Filters.Date{
        filter_value_1: @test_value,
        filter_type_2: "after",
        filter_value_2: "2024-01-01",
        combinator: "or",
        enabled: true
      }

      assert Filters.Date.get_query(filter, @field_name) == %{
               "$or": [
                 %{@field_name => %{:"$lt" => ~U[2024-01-10T00:00:00Z]}},
                 %{@field_name => %{:"$gt" => ~U[2024-01-01T23:59:59Z]}}
               ]
             }
    end

    test "disabled filter returns no query" do
      refute %Filters.Date{
               enabled: false
             }
             |> Filters.Date.get_query(@test_value)
    end
  end
end
