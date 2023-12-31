# cspell: ignore subquery
defmodule LiveViewGrid.Filters.Date do
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

  def parse(d) do
    d |> Timex.parse!("%Y-%m-%d", :strftime) |> Timex.to_datetime()
  end

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
    %{field_name => %{"$exists": false}}
  end

  def get_subquery("not_blank", _value, field_name) do
    %{field_name => %{"$exists": true}}
  end
end
