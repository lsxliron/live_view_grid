# cspell: ignore subquery
defmodule LiveViewGrid.Filters.Date do
  @moduledoc """
  This is a date filter object which holds all the required information in order to extract a meaningful to generate a filter query.
  A filter object may have at most two conditions that can be combined using a `or`/ `and` logical operators.

  A filter object have the following attributes:
  - `filter_value_1` - the lookup values of the first condition
  - `filter_type_1` - the query type. In a `DateFilter` context, this might be before, after, equals, not equals, blank or not blank
  - `filter_value_2` - same as `filter_value_1`
  - `filter_type_2` - same as `filter_type_1`
  - `enabled` - wether or not the filter is enabled or not. This field is automatically changing based on the filter values. A filter is disabled
     if both its `filter_values` are empty
  - `combinator` - in case the second condition is enabled (e.g. `filter_value_2` is non-empty), how the filters will be combined (`or`, or `and`)
  """

  @behaviour LiveViewGrid.Behaviours.BaseFilter

  defstruct filter_value_1: "",
            filter_type_1: "before",
            filter_value_2: "",
            filter_type_2: "before",
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
  Parses a string to a DateTime. The string should be in `YYYY-MM-DD` format

  ## Parameters
  - `d` - the string to parse

  ## Examples
  ```
     iex> parse("2020-11-10")
     ~U[2020-11-10 00:00:00Z]
  ```
  """
  def parse(d) do
    d |> Timex.parse!("%Y-%m-%d", :strftime) |> Timex.to_datetime()
  end

  @doc """
  constructs the query based on the search condition (first parameter), value and field name

  ## Parameters
  - `value` - the search value
  - `field_name` - the field name to apply the query on
  """
  @spec get_subquery(String.t(), String.t(), String.t()) :: map()
  def get_subquery("after", value, field_name) do
    %{field_name => %{"$gt": Timex.end_of_day(parse(value))}}
  end

  def get_subquery("before", value, field_name) do
    %{field_name => %{"$lt": parse(value)}}
  end

  def get_subquery("equals", value, field_name) do
    %{
      "$and": [
        %{field_name => %{"$gte": parse(value)}},
        %{field_name => %{"$lte": Timex.end_of_day(parse(value))}}
      ]
    }
  end

  def get_subquery("not_equals", value, field_name) do
    %{field_name => %{"$eq": parse(value)}}
  end

  def get_subquery("blank", _value, field_name) do
    %{"$or": [%{field_name => %{"$exists": false}}, %{field_name => %{"$eq": nil}}]}
  end

  def get_subquery("not_blank", _value, field_name) do
    %{"$and": [%{field_name => %{"$exists": true}}, %{field_name => %{"$ne": nil}}]}
  end
end
