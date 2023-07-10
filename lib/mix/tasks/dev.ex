defmodule Mix.Tasks.Dev do
  use Mix.Task
  require Logger

  def run(_) do
    tailwind =
      Task.async(fn ->
        Mix.shell().cmd("mix tailwind default --minify --watch")
      end)

    esbuild =
      Task.async(fn ->
        Mix.shell().cmd("mix esbuild default --minify --watch")
      end)
      Task.await_many([tailwind, esbuild], :infinity)
  end
end
