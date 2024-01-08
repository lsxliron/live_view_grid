opts = [strategy: :one_for_one, name: LiveViewGrid.Supervisor]
Supervisor.start_link([LiveViewGrid.Endpoint], opts)
ExUnit.start()
