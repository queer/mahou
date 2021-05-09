defmodule Agma.Docker.Container do
  use TypedStruct

  @type id() :: String.t()
  @type name() :: String.t()

  typedstruct do
    field :id, id()
    field :names, [name()]
    field :image, String.t()
    field :image_id, id()
    field :command, String.t() | nil
    field :created, non_neg_integer()
    field :state, String.t()
    field :status, String.t()
    field :ports, [__MODULE__.Port.t()]
    field :labels, %{required(String.t()) => String.t()}
    field :size_rw, non_neg_integer()
    field :size_root_fs, non_neg_integer()
    field :host_config, __MODULE__.HostConfig.t()
    field :network_settings, __MODULE__.NetworkSettings.t()
    field :mounts, [__MODULE__.Mount.t()]
  end

  typedstruct module: CreatableContainer do
    field :app_armor_profile, String.t() | nil
    field :args, [String.t()]
    field :command, String.t()
    field :config, Container.Config.t()
    field :created, NaiveDateTime.t() # TODO: tz?
    field :driver, String.t()
    field :exec_ids, [Container.id()] # TODO: What dis
    field :host_config, Container.HostConfig.t()
    field :hostname_path, String.t()
    field :hosts_path, String.t()
    field :log_path, String.t()
    field :id, Container.id()
    field :image, Container.id()
    field :mount_label, String.t() | nil
    field :name, Container.name()
    field :network_settings, Container.NetworkSettings.t()
    field :path, Path.t()
    field :process_label, String.t() # TODO: What is?
    field :resolv_conf_path, Path.t()
    field :restart_count, non_neg_integer()
    field :state, Container.State.t()
    field :mounts, [Container.Mount.t()]
  end

  typedstruct module: Config do
    field :attach_stderr, boolean()
    field :attach_stdin, boolean()
    field :attach_stdout, boolean()
    field :cmd, [String.t()]
    field :domain_name, String.t() | nil
    field :env, [String.t()]
    field :healthcheck, %{required(String.t()) => [String.t()]}
    field :hostname, String.t()
    field :image, String.t()
    field :labels, %{required(String.t()) => String.t()}
    field :mac_address, String.t() | nil
    field :network_disabled, boolean()
    field :open_stdin, boolean()
    field :stdin_once, boolean()
    field :tty, boolean()
    field :user, String.t() | nil
    field :volumes, %{required(String.t()) => map()} # TODO: inner type??
    field :working_dir, String.t() | nil
    field :stop_signal, String.t()
    field :stop_timeout, non_neg_integer()
  end

  typedstruct module: HostConfig do
    field :maximum_iops, non_neg_integer()
    field :maximum_io_bps, non_neg_integer()
    field :blkio_weight, non_neg_integer()
    field :blkio_weight_device, [map()]
    field :blkio_device_read_bps, [map()]
    field :blkio_device_write_bps, [map()]
    field :blkio_device_read_iops, [map()]
    field :blkio_device_write_iops, [map()]
    field :container_id_file, Path.t() | nil
    field :cpuset_cpus, String.t() | nil
    field :cpuset_mems, String.t() | nil
    field :cpu_percent, non_neg_integer()
    field :cpu_shares, non_neg_integer()
    field :cpu_period, non_neg_integer()
    field :cpu_realtime_period, non_neg_integer()
    field :cpu_realtime_runtime, non_neg_integer()
    field :devices, [term()] # TODO: Real type?
    field :device_requests, [map()] # TODO: DeviceRequest struct
    field :ipc_mode, String.t() | nil
    field :lxc_conf, [term()] # TODO: what type?
    field :memory, non_neg_integer()
    field :memory_swap, non_neg_integer()
    field :memory_reservation, non_neg_integer()
    field :kernel_memory, non_neg_integer()
    field :oom_kill_disable, boolean()
    field :ook_score_adj, non_neg_integer()
    field :network_mode, String.t()
    field :pid_mode, String.t() | nil
    field :port_bindings, map() # TODO: What does this look like?
    field :privileged, boolean()
    field :readonly_rootfs, boolean()
    field :publish_all_ports, boolean()
    field :restart_policy, %{maximum_retry_count: non_neg_integer(), name: String.t()}
    field :log_config, %{type: String.t()}
    field :sysctls, %{required(String.t()) => String.t()}
    field :ulimits, [map()] # TODO: Real type?
    field :volume_driver, String.t() | nil
    field :shm_size, non_neg_integer()
  end

  typedstruct module: NetworkSettings do
    field :bridge, String.t() | nil
    field :sandbox_id, String.t() | nil
    field :hairpin_mode, boolean()
    field :link_local_ipv6_address, String.t() | nil
    field :link_local_ipv6_prefix_len, non_neg_integer()
    field :sandbox_key, String.t() | nil
    field :endpoint_id, String.t() | nil
    field :gateway, String.t() | nil
    field :global_ipv6_address, String.t() | nil
    field :global_ipv6_prefix_len, non_neg_integer()
    field :ip_address, String.t() | nil
    field :ip_prefix_len, non_neg_integer()
    field :ipv6_gateway, String.t() | nil
    field :mac_address, String.t() | nil
    field :networks, %{required(String.t()) => Agma.Docker.Container.Network.t()}
  end

  typedstruct module: Network do
    field :network_id, Container.id()
    field :endpoint_id, Container.id()
    field :gateway, String.t()
    field :ip_address, String.t()
    field :ip_prefix_len, non_neg_integer()
    field :ipv6_gateway, String.t() | nil
    field :global_ipv6_address, String.t() | nil
    field :global_ipv6_prefix_len, non_neg_integer()
    field :mac_address, String.t()
    field :aliases, [String.t()] | nil
    field :driver_opts, term() # TODO: What is this
    field :ipam_config, term() # TODO: ?
    field :links, term() # TODO: haha what
  end

  typedstruct module: State do
    field :error, String.t() | nil
    field :exit_code, integer()
    field :finished_at, NaiveDateTime.t()
    field :health, __MODULE__.Health.t()
    field :oom_killed, boolean()
    field :dead, boolean()
    field :paused, boolean()
    field :pid, non_neg_integer()
    field :restarting, boolean()
    field :running, boolean()
    field :started_at, NaiveDateTime.t()
    field :status, String.t() # TODO: Convert to enum

    typedstruct module: Health do
      field :status, String.t()
      field :failing_streak, non_neg_integer()
      field :log, [map()] # TODO: Real type?
    end
  end

  typedstruct module: Mount do
    field :name, String.t()
    field :source, String.t() | nil
    field :destination, String.t()
    field :driver, String.t()
    field :mode, String.t() | nil
    field :rw, boolean()
    field :propagation, String.t() | nil
    field :type, String.t()
  end

  typedstruct module: Port do
    field :ip, String.t() | nil
    field :private_port, non_neg_integer()
    field :public_port, non_neg_integer()
    field :type, String.t()
  end

  def from(json) do
    struct! __MODULE__, %{
      json
      | ports: ports(json.ports),
        host_config: host_config(json.host_config),
        network_settings: network_settings(json.network_settings),
        mounts: mounts(json.mounts),
        labels: json.labels
    }
  end

  defp ports(ports) do
    Enum.map ports, &struct!(__MODULE__.Port, &1)
  end

  defp host_config(hcon) do
    struct! __MODULE__.HostConfig, hcon
  end

  defp network_settings(network) do
    struct! __MODULE__.NetworkSettings, %{network | networks: networks(network.networks)}
  end

  defp networks(networks) do
    networks
    |> Enum.map(fn {k, v} ->
      {k, struct!(__MODULE__.Network, v)}
    end)
    |> Enum.into(%{})
  end

  defp mounts(mounts) do
    Enum.map mounts, &struct!(__MODULE__.Mount, &1)
  end
end
