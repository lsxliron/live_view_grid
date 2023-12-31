# cspell: ignore subquery
defmodule LiveViewGrid.Filters.Number do
  @moduledoc """
  This is a number filter object which holds all the required information in order to extract a meaningful to generate a filter query.
  A filter object may have at most two conditions that can be combined using a `or`/ `and` logical operators.

  A filter object have the following attributes:
  - `filter_value_1` - the lookup values of the first condition
  - `filter_type_1` - the query type. In a `NumberFilter` context, this might be greater then, greater than or equal, less then, less than or equal,
     equals, not equals, blank or not blank
  - `filter_value_2` - same as `filter_value_1`
  - `filter_type_2` - same as `filter_type_1`
  - `enabled` - wether or not the filter is enabled or not. This field is automatically changing based on the filter values. A filter is disabled
     if both its `filter_values` are empty
  - `combinator` - in case the second condition is enabled (e.g. `filter_value_2` is non-empty), how the filters will be combined (`or`, or `and`)
  """

  @behaviour LiveViewGrid.Behaviours.BaseFilter
  defstruct filter_value_1: "",
            filter_type_1: "greater",
            filter_value_2: "",
            filter_type_2: "greater",
            enabled: false,
            combinator: "and"

  @type t :: %__MODULE__{
          filter_value_1: String.t(),
          filter_type_1: String.t(),
          filter_value_2: String.t(),
          filter_type_2: String.t(),
          enabled: boolean(),
          combinator: String.t()
        }
  @type filter_params :: %{
          filter_value_1: String.t(),
          filter_type_1: String.t(),
          filter_value_2: String.t(),
          filter_type_2: String.t(),
          enabled: boolean(),
          combinator: String.t()
        }

  @doc """
  Returns the query that is required in order to fulfill the filter conditions

  ## Parameters
  - `filter` - the filter to get the query for
  - `field_name` - the field name that the query applies to
  """
  @spec get_query(t(), String.t()) :: map() | nil
  def get_query(%__MODULE__{enabled: false}, _field_name), do: nil

  def get_query(%__MODULE__{filter_value_1: value1, filter_value_2: value2} = filter, field_name)
      when value2 == "" do
    get_subquery(filter.filter_type_1, value1, field_name)
  end

  def get_query(filter, field_name) do
    filter_1 = get_subquery(filter.filter_type_1, filter.filter_value_1, field_name)
    filter_2 = get_subquery(filter.filter_type_2, filter.filter_value_2, field_name)

    if filter.combinator == "and" do
      %{"$and": [filter_1, filter_2]}
    else
      %{"$or": [filter_1, filter_2]}
    end
  end

  @doc """
  Parses a string to a number

  ## Parameters
  - `n` - the string to parse

  ## Examples
  ```
     iex> parse("")
     0
     iex> parse(nil)
     0
     iex> parse("12")
     12
     iex> parse("1.2")
     1.2
  ```
  """
  @spec parse(String.t() | nil) :: number()
  def parse(""), do: 0
  def parse(nil), do: 0

  def parse(n) do
    if String.contains?(n, ".") do
      String.to_float(n)
    else
      String.to_integer(n)
    end
  end

  @doc """
  constructs the query based on the search condition (first parameter), value and field name

  ## Parameters
  - `value` - the search value
  - `field_name` - the field name to apply the query on
  """
  @spec get_subquery(String.t(), String.t(), String.t()) :: map()
  def get_subquery("greater", value, field_name) do
    %{field_name => %{"$gt": parse(value)}}
  end

  def get_subquery("greater_equal", value, field_name) do
    %{field_name => %{"$gte": parse(value)}}
  end

  def get_subquery("less", value, field_name) do
    %{field_name => %{"$lt": parse(value)}}
  end

  def get_subquery("less_equal", value, field_name) do
    %{field_name => %{"$lte": parse(value)}}
  end

  def get_subquery("equals", value, field_name) do
    %{field_name => %{"$eq": parse(value)}}
  end

  def get_subquery("not_equals", value, field_name) do
    %{field_name => %{"$ne": parse(value)}}
  end

  def get_subquery("blank", _value, field_name) do
    %{"$or": [%{field_name => %{"$exists": false}}, %{field_name => %{"$eq": nil}}]}
  end

  def get_subquery("not_blank", _value, field_name) do
    %{"$and": [%{field_name => %{"$exists": true}}, %{field_name => %{"$ne": nil}}]}
  end
end
