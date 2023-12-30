# cspell: ignore subquery
defmodule LiveViewGrid.Filters.Number do
  defstruct filter_value_1: "",
            filter_type_1: "greater",
            filter_value_2: "",
            filter_type_2: "greater",
            enabled: false,
            combinator: "and"

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

  def parse(""), do: 0
  def parse(nil), do: 0

  def parse(n) do
    if String.contains?(n, ".") do
      String.to_float(n)
    else
      String.to_integer(n)
    end
  end

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
    %{field_name => %{"$exists": false}}
  end

  def get_subquery("not_blank", _value, field_name) do
    %{field_name => %{"$exists": true}}
  end
end
