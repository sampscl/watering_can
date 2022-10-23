ESpec.configure(fn config ->
  Ecto.Adapters.SQL.Sandbox.mode(Db.Repo, :manual)

  config.before(fn tags ->
    {:shared, [], tags: tags}
  end)

  config.finally(fn _shared ->
    :ok
  end)
end)
