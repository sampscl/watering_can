defmodule Utils.Logger do
  @moduledoc """
  Utilities supporting logging. This generally works with `LoggerFileBackend`,
  in particular `setup_log`, though it also can be used with other log backends.

  usage:
  ```
  defmodule MyModule do
    use Utils.Logger

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
end
