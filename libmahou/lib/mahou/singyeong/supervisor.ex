defmodule Mahou.Singyeong.Supervisor do
  use DynamicSupervisor
  alias Mahou.Singyeong

  def start_link(state) do
    DynamicSupervisor.start_link __MODULE__, state, name: __MODULE__
  end

  def init({dsn, consumer}) do
    me = self()
    spawn fn ->
      # TODO: lol
      :ok = spin_on_parent me
      start_children Singyeong.child_specs(dsn, consumer)
    end
    DynamicSupervisor.init strategy: :one_for_one
  end

  def start_children(children) do
    for child <- children, do: DynamicSupervisor.start_child __MODULE__, child
    :ok
  end

  defp spin_on_parent(pid) do
    pid
    |> Process.info(:monitored_by)
    |> elem(1)
    |> Enum.map(fn monitor ->
      status =
        monitor
        |> Process.info(:status)
        |> elem(1)

      status not in [:exiting, :suspended]
    end)
    |> Enum.all?
    |> if do
      :ok
    else
      :timer.sleep 10
      spin_on_parent pid
    end
  end
end
