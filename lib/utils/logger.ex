defmodule Utils.Logger do
  @moduledoc """
  Utilities supporting logging. This generally works with `LoggerFileBackend`,
  in particular `setup_log`, though it also can be used with other log backends.

  usage:
  ```
  defmodule MyModule do
    use Utils.Logger, id: :some_atom

    def foo do
      # equivalent to `Logger.debug("Foo", some_atom: true, mfa: "MyModule.foo/1", file: "my_module.ex", line: 6)`
      log_debug("Foo!")
    end
  end
  ```
  """
  require Logger

  @spec pretty_stack() :: list(String.t())
  @doc """
  Prettify the results from `Process.info(:current_stacktrace)`, returning a list
  if items that inspect cleanly.

  ## Returns
  - [String.t()]
  """
  def pretty_stack do
    {:current_stacktrace, [_me, _process_info | fs]} = Process.info(self(), :current_stacktrace)

    Enum.map(fs, fn info_silliness ->
      # The return from Process.info is not very pretty, so make it nicer
      {m, f, a, kwl} = info_silliness
      fl = Keyword.get(kwl, :file)
      l = Keyword.get(kwl, :line)

      "#{m}.#{f}/#{a} (#{fl}:#{l})"
    end)
  end

  @doc """
  Use this module to introduce logging utilities, most of which mimic `Logger.*` functions:
    - `log_warning`
    - `log_error`
    - `log_info`
    - `log_debug`
    - `log_trace`: Logs the call stack and all local variables at `:debug` level from the call site.
  ## Parameters
  - `opts` Keyword list of options:
    * `{id: identity}` The id of the using module, used as metadata in logs (`{id: true}`); defaults to `:application`
  """
  defmacro __using__(opts \\ []) do
    id = Keyword.get(opts, :id, :application)

    quote do
      require Logger

      defmacro log_debug(message_or_fun, metadata \\ []) do
        m = [
          {unquote(id), true},
          {:mfa, "#{__CALLER__.module}.#{elem(__CALLER__.function, 0)}/#{elem(__CALLER__.function, 1)}"},
          {:file, Path.relative_to_cwd(__CALLER__.file)},
          {:line, __CALLER__.line}
          | metadata
        ]

        quote do
          Logger.debug(unquote(message_or_fun), unquote(m))
        end
      end

      defmacro log_warning(message_or_fun, metadata \\ []) do
        m = [
          {unquote(id), true},
          {:mfa, "#{__CALLER__.module}.#{elem(__CALLER__.function, 0)}/#{elem(__CALLER__.function, 1)}"},
          {:file, Path.relative_to_cwd(__CALLER__.file)},
          {:line, __CALLER__.line}
          | metadata
        ]

        quote do
          Logger.warning(unquote(message_or_fun), unquote(m))
        end
      end

      defmacro log_error(message_or_fun, metadata \\ []) do
        m = [
          {unquote(id), true},
          {:mfa, "#{__CALLER__.module}.#{elem(__CALLER__.function, 0)}/#{elem(__CALLER__.function, 1)}"},
          {:file, Path.relative_to_cwd(__CALLER__.file)},
          {:line, __CALLER__.line}
          | metadata
        ]

        quote do
          Logger.error(unquote(message_or_fun), unquote(m))
        end
      end

      defmacro log_info(message_or_fun, metadata \\ []) do
        m = [
          {unquote(id), true},
          {:mfa, "#{__CALLER__.module}.#{elem(__CALLER__.function, 0)}/#{elem(__CALLER__.function, 1)}"},
          {:file, Path.relative_to_cwd(__CALLER__.file)},
          {:line, __CALLER__.line}
          | metadata
        ]

        quote do
          Logger.info(unquote(message_or_fun), unquote(m))
        end
      end

      defmacro log_trace(metadata \\ []) do
        m = [
          {unquote(id), true},
          {:mfa, "#{__CALLER__.module}.#{elem(__CALLER__.function, 0)}/#{elem(__CALLER__.function, 1)}"},
          {:file, Path.relative_to_cwd(__CALLER__.file)},
          {:line, __CALLER__.line}
          | metadata
        ]

        quote do
          Logger.debug(inspect([stack: Utils.Logger.pretty_stack(), binding: binding()], pretty: true, limit: :infinity), unquote(m))
        end
      end
    end
  end

  @spec(setup_log(keyword()) :: :ok, {:error, any()})
  @doc """
  Add and configure a single log file with `LoggerFileBackend`.

  ## Parameters
  - `opts` Keyword list of options, also accepts all options to `Logger.configure_backend` for `LoggerFileBackend`
    * `log_dir: ""` The log directory, defaults to `System.get_env("APP_ROOT", File.cwd!())`
    * `id: :application` The backend identifier atom, used to identify the log, set the log file name, and filter log metadata. Default: `:application`

  ## Returns
  - `:ok` All is well
  - `{:error, reason}` Failed for reason
  """
  def setup_log(opts) do
    {log_dir, opts_without_log_dir} = Keyword.pop(opts, :log_dir, System.get_env("APP_ROOT", File.cwd!()))
    {id, opts_without_id} = Keyword.pop(opts_without_log_dir, :id, :application)
    default_path = Path.join([log_dir, "#{Atom.to_string(id)}.log"])

    configuration_opts =
      opts_without_id
      |> Keyword.update(:metadata_filter, [{id, true}], fn old_filter -> [{id, true} | old_filter] end)
      |> Keyword.put_new(:path, default_path)

    backend = {LoggerFileBackend, id}

    # Logger.debug(inspect([opts: opts, backend: backend, configuration_opts: configuration_opts], pretty: true, limit: :infinity))

    with {:add_backend, true} <- {:add_backend, on_start_child_success?(Logger.add_backend(backend))},
         {:configure_backend, _wth} <- {:configure_backend, Logger.configure_backend(backend, configuration_opts)} do
      :ok
    else
      {:add_backend, false} -> {:error, "failed to add backend #{inspect(backend)}"}
      {:configure_backend, _reason} = reason -> {:error, reason}
    end
  end

  @spec on_start_child_success?(Supervisor.on_start_child()) :: boolean()
  defp on_start_child_success?({:ok, _child}), do: true
  defp on_start_child_success?(_error), do: false
end
