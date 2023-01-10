ESpec.configure(fn config ->
  Ecto.Adapters.SQL.Sandbox.mode(Db.Repo, :manual)

  config.before(fn tags ->
    {:ok, _} = Application.ensure_all_started(:ex_machina)
    {:shared, [], tags: tags}
  end)

  config.finally(fn _shared ->
    :ok
  end)
end)
