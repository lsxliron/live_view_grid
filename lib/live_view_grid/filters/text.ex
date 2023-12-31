# cspell: ignore subquery
defmodule LiveViewGrid.Filters.Text do
  defstruct filter_value_1: "",
            filter_type_1: "contains",
            filter_value_2: "",
            filter_type_2: "contains",
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

  def get_subquery("contains", value, field_name) do
    %{field_name => %{"$regex": ".*#{value}.*", "$options": "i"}}
  end

  def get_subquery("not_contains", value, field_name) do
    %{field_name => %{"$not": %{"$regex": ".*#{value}.*", "$options": "i"}}}
  end

  def get_subquery("equals", value, field_name) do
    # %{field_name => %{"$eq": value}}
    # using regex instead of $eq so queries wont be case-sensitive
    %{field_name => %{"$regex": "^#{value}$", "$options": "i"}}
  end

  def get_subquery("not_equals", value, field_name) do
    # %{field_name => %{"$ne": value}}
    # using regex instead of $ne so queries wont be case-sensitive
    %{field_name => %{"$not": %{"$regex": "^#{value}$", "$options": "i"}}}
  end

  def get_subquery("blank", _value, field_name) do
    %{"$or": [%{field_name => %{"$exists": false}}, %{field_name => %{"$eq": ""}}]}
  end

  def get_subquery("not_blank", _value, field_name) do
    %{"$and": [%{field_name => %{"$exists": true}}, %{field_name => %{"$ne": ""}}]}
    # %{field_name => %{"$exists": true}}
  end
end
