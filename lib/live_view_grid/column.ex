defmodule LiveViewGrid.Column do
  @moduledoc """
  A column definition module
  """

  @type data_type :: :text | :date | :number

  @typedoc """
  the column definition holds the required metadata about a single columns in the grid:
  - `field` (required) - the field name in the map that will feed the data
  - `data_type` (required) - the field data type. Can be one of `:text`, `:number` or `:date`.
  - `header` - the title that the column will have (whatever value will be displayed to the user)
  - `formatter` - a function that can manipulate the value (for example add currency to prices)
  - `filter` - a filter object (docs TBD)
  """
  @type t :: %__MODULE__{
          field: String.t(),
          header: String.t(),
          formatter: fun(),
          filter: any(),
          data_type: data_type()
        }

  @enforce_keys [:field, :data_type]
  defstruct [:field, :header, :formatter, :filter, data_type: :text]

  @doc """
  initializes the column def with default values
  """
  @spec init(t()) :: t()
  def init(coldef) do
    coldef
    |> add_header()
    |> add_formatter()
    |> add_filter()
  end

  @doc """
  Adds the default filter according the the column data type

  ## Parameters
  - `coldef` - the column definition to add the filter to
  """
  @spec add_filter(t()) :: t()
  def add_filter(%__MODULE__{data_type: :text, filter: nil} = coldef) do
    Map.put(coldef, :filter, %LiveViewGrid.Filters.Text{})
  end

  def add_filter(%__MODULE__{data_type: :date, filter: nil} = coldef) do
    Map.put(coldef, :filter, %LiveViewGrid.Filters.Date{})
  end

  def add_filter(%__MODULE__{data_type: :number, filter: nil} = coldef) do
    Map.put(coldef, :filter, %LiveViewGrid.Filters.Number{})
  end

  @doc """
  Adds the identity formatter if a formatter is not given

  ## Parameters
  - `coldef` - the column definition to add the formatter to
  """
  @spec add_formatter(t()) :: t()
  def add_formatter(%__MODULE__{formatter: nil} = coldef) do
    Map.put(coldef, :formatter, fn v, _row -> v end)
  end

  def add_formatter(%__MODULE__{formatter: f} = coldef) when not is_nil(f) do
    coldef
  end

  @doc """
  Adds a header to the column definition if one is not already given.
  Default headers are title case `field_names`. so `my_field` becomes `My Field`

  ## Parameters
  - `coldef` - the column definition to add the header to
  """
  @spec add_header(t()) :: t()
  def add_header(%__MODULE__{header: nil, field: field} = coldef) do
    header = field |> String.split("_") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
    Map.put(coldef, :header, header)
  end

  def add_header(%__MODULE__{header: header} = coldef) when not is_nil(header) do
    coldef
  end
end
