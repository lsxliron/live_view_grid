defmodule LiveViewGrid.GridCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint LiveViewGrid.Endpoint
      import Phoenix.LiveViewTest
      import LiveViewGrid.GridCase
    end
  end

  setup _context do
    {:ok, %{conn: Phoenix.ConnTest.build_conn()}}
  end
end
