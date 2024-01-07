defmodule LiveViewGrid.Filters.TextTest do
  use ExUnit.Case, async: true
  alias LiveViewGrid.Filters

  doctest LiveViewGrid.Filters.Number, import: true

  @field_name "test_filed"
  @test_value "abc"

  describe "LiveViewGrid.Filters.Text" do
    test "return proper query for contains" do
      assert Filters.Text.get_subquery("contains", @test_value, @field_name) == %{
               @field_name => %{:"$regex" => ".*#{@test_value}.*", "$options": "i"}
             }
    end

    test "return proper query for not contains" do
      assert Filters.Text.get_subquery("not_contains", @test_value, @field_name) == %{
               @field_name => %{:"$not" => %{:"$regex" => ".*#{@test_value}.*", "$options": "i"}}
             }
    end

    test "return proper query for equals" do
      assert Filters.Text.get_subquery("equals", @test_value, @field_name) == %{
               @field_name => %{:"$regex" => "^#{@test_value}$", "$options": "i"}
             }
    end

    test "return proper query for not equals" do
      assert Filters.Text.get_subquery("not_equals", @test_value, @field_name) == %{
               @field_name => %{:"$not" => %{:"$regex" => "^#{@test_value}$", "$options": "i"}}
             }
    end

    test "return proper query for not blank" do
      assert Filters.Text.get_subquery("not_blank", @test_value, @field_name) == %{
               "$and": [
                 %{@field_name => %{:"$exists" => true}},
                 %{@field_name => %{:"$ne" => ""}}
               ]
             }
    end

    test "return proper query for blank" do
      assert Filters.Text.get_subquery("blank", @test_value, @field_name) == %{
               "$or": [
                 %{@field_name => %{:"$exists" => false}},
                 %{@field_name => %{:"$eq" => ""}}
               ]
             }
    end

    test "can get a query with a single filter" do
      filter = %Filters.Text{filter_value_1: @test_value, enabled: true}

      assert Filters.Text.get_query(filter, @field_name) == %{
               @field_name => %{:"$regex" => ".*#{@test_value}.*", "$options": "i"}
             }
    end

    test "can get a query with a complex and filter" do
      filter = %Filters.Text{
        filter_value_1: @test_value,
        filter_type_2: "not_contains",
        filter_value_2: "def",
        enabled: true
      }

      assert Filters.Text.get_query(filter, @field_name) == %{
               "$and": [
                 %{@field_name => %{:"$regex" => ".*#{@test_value}.*", "$options": "i"}},
                 %{
                   @field_name => %{
                     :"$not" => %{:"$regex" => ".*def.*", "$options": "i"}
                   }
                 }
               ]
             }
    end

    test "can get a query with a complex or filter" do
      filter = %Filters.Text{
        filter_value_1: @test_value,
        filter_type_2: "contains",
        filter_value_2: "def",
        enabled: true,
        combinator: "or"
      }

      assert Filters.Text.get_query(filter, @field_name) == %{
               "$or": [
                 %{@field_name => %{:"$regex" => ".*#{@test_value}.*", "$options": "i"}},
                 %{
                   @field_name => %{:"$regex" => ".*def.*", "$options": "i"}
                 }
               ]
             }
    end

    test "disabled filter returns no query" do
      refute %Filters.Text{
               enabled: false
             }
             |> Filters.Text.get_query(@test_value)
    end
  end
end
