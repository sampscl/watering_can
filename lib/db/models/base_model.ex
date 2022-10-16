# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule Db.Models.BaseModel do
  @moduledoc """
  The base model used by db models. Provides many useful support macros. Users must, at a minimum
  provide `create_changeset(t(), keyword() | map())` and `update_changeset(t(), keyword() | map())`.
  """

  @doc """
  using macro; opts is a keyword list:
    * `no_alias: [function]` Prevent aliasing the function(s) (create/find/where etc.). For instance,
      to override Db.Models.Foo.create:
      ```
      defmodule Db.Models.Foo do
        use Db.Models.BaseModel, no_alias: [:create]
        def create(params) do
          # custom create logic here...
        end
      end
      ```
  """
  defmacro __using__(opts) do
    no_alias = Keyword.get(opts, :no_alias, [])

    quote do
      use Ecto.Schema
      require Ecto.Query
      require Ecto.Changeset

      @type t :: %__MODULE__{}

      @type ecto_query() :: Ecto.Query.t()

      @spec base_create(keyword()) :: {:ok, t()} | {:error, any()}
      @doc false
      def base_create(params), do: Db.Repo.insert(create_changeset(params))

      @spec base_find(term()) :: {:ok, t()} | {:error, :not_found}
      @doc false
      def base_find(id) do
        pk = __MODULE__.__schema__(:primary_key) |> hd

        result = Db.Repo.one(Ecto.Query.from(record in __MODULE__, where: field(record, ^pk) == ^id))

        case result do
          nil -> {:error, :not_found}
          model -> {:ok, model}
        end
      end

      @spec base_where(keyword()) :: list(t())
      @doc false
      def base_where(params), do: Db.Repo.all(build_query(params))

      @spec base_update(t(), keyword() | map()) :: {:ok, t()} | {:error, any()}
      @doc false
      def base_update(model, params), do: Db.Repo.update(update_changeset(model, params))

      @spec base_update_model(t()) :: {:ok, t()} | {:error, any()}
      @doc false
      def base_update_model(model) do
        pk = __MODULE__.__schema__(:primary_key) |> hd
        id = Map.get(model, pk)

        case find(id) do
          {:ok, existing} -> update(existing, Map.from_struct(model))
          error -> error
        end
      end

      @spec base_delete_where(keyword()) :: {non_neg_integer(), nil | [term()]}
      @doc false
      def base_delete_where(params), do: Db.Repo.delete_all(build_query(params))

      @spec base_delete(term) :: {non_neg_integer(), nil | [term()]}
      @doc false
      def base_delete(id) do
        pk = __MODULE__.__schema__(:primary_key) |> hd

        Db.Repo.delete_all(Ecto.Query.from(record in __MODULE__, where: field(record, ^pk) == ^id))
      end

      @spec base_build_query(keyword()) :: ecto_query()
      @doc false
      def base_build_query(params) do
        Enum.reduce(params, Ecto.Query.from(record in __MODULE__), fn
          {k, nil}, acc ->
            Ecto.Query.from(record in acc, where: is_nil(field(record, ^k)))

          {:order_by, fields}, acc ->
            Ecto.Query.order_by(acc, ^fields)

          {:order_by_ci, fields}, acc ->
            Enum.reduce(fields, acc, fn {direction, field_name}, inner_acc ->
              Ecto.Query.from(inner_acc, order_by: ^{direction, Ecto.Query.dynamic([__MODULE__], fragment("lower(?)", field(__MODULE__, ^field_name)))})
            end)

          {:limit, count}, acc ->
            Ecto.Query.limit(acc, ^count)

          {:offset, count}, acc ->
            Ecto.Query.offset(acc, ^count)

          {k, v}, acc ->
            Ecto.Query.from(record in acc, where: field(record, ^k) == ^v)
        end)
      end

      @spec base_first(keyword()) :: {:ok, t()} | {:error, :not_found}
      @doc false
      def base_first(params) do
        params
        |> build_query()
        |> Ecto.Query.limit(1)
        |> Db.Repo.one()
        |> then(fn
          nil -> {:error, :not_found}
          model -> {:ok, model}
        end)
      end

      @spec count() :: term()
      @doc """
      Get the count of records
      """
      def count, do: Db.Repo.one(Ecto.Query.from(x in __MODULE__, select: count(1)))

      @spec all() :: list(t())
      @doc """
      Get a list of all records
      """
      def all, do: Db.Repo.all(__MODULE__)

      @spec preload(t() | {:ok, t()} | list(t()), list(atom()), keyword()) ::
              t() | {:ok, t()} | list(t())
      @doc """
      Preload an already-loaded structure, see `Ecto.Repo.preload/3`.
      ## Parameters
      - `item` one of: %__MODULE__{}, {:ok, %__MODULE__{}}, nil, or [%__MODULE__{}]
      - `preload_fields` list of fields to preload
      - `opts` See `Db.Repo.preload/3`
      ## Returns
      - `preloaded_model` when a single model is passed in, a preloaded model is returned
      - `[preloaded_model]` when a list of models is passed in, a list of preloaded models is returned
      - `{:ok, preloaded_model}` when an ok tuple is passed in, an ok tuple with a preloaded model is returned
      """
      def preload(item, preload_fields, opts \\ [])
      def preload({:ok, model}, preloads, opts), do: {:ok, Db.Repo.preload(model, preloads, opts)}

      def preload(structs_or_struct_or_nil, preloads, opts),
        do: Db.Repo.preload(structs_or_struct_or_nil, preloads, opts)

      defoverridable base_create: 1,
                     base_find: 1,
                     base_where: 1,
                     base_update: 2,
                     base_delete_where: 1,
                     base_delete: 1,
                     base_build_query: 1,
                     base_first: 1

      if :create not in unquote(no_alias) do
        @spec create(keyword) :: {:ok, t()} | {:error, any()}
        @doc """
        Create a record
        ## Parameters
        - `params` Keyword list of `[{:column_name, value}]` for the new record
        ## Returns
        - `{:ok, model}` All is well
        - `{:error, reason}` Failed for reason
        """
        def create(params), do: base_create(params)
      end

      if :find not in unquote(no_alias) do
        @spec find(any()) :: {:ok, t()} | {:error, :not_found}
        @doc """
        Find a record
        ## Parameters
        - `id` The value of the record's primary key
        ## Returns
        - `{:ok, model}` All is well
        - `{:error, :not_found}` No record with that pk exists
        """
        def find(id), do: base_find(id)
      end

      if :where not in unquote(no_alias) do
        @spec where(keyword()) :: list(t())
        @doc """
        Get all matching records
        ## Parameters
        - `params` Keyword list:
          * `[{:column_name, value}]` to filter records
          * `[{:column_name, nil}]` to filter records with nil values
          * `[{:limit, count]` limit to count records
          * `[{:offset, count]` offset count records into the result set
          * `[{:order_by, order_by]` order results; see https://hexdocs.pm/ecto/Ecto.Query.html#order_by/3
          * `[{:order_by_ci, order_by]` order results with case-insensitive string compares; otherwise just like `order_by`
        ## Returns
        - `[model]` A list of models filtered by `params`.
        """
        def where(params), do: base_where(params)
      end

      if :update not in unquote(no_alias) do
        @spec update(t(), keyword() | map()) :: {:ok, t()} | {:error, any()}
        @doc """
        Update a record
        ## Parameters
        - `model` The model to update
        - `params` Keyword list of `[{:column_name, value}]` to filter all records by
        ## Returns
        - `{:ok, updated_model}` All is well, updated_model is what was commited to the database
        - `{:error, reason}` Failed for reason
        """
        def update(model, params), do: base_update(model, params)
      end

      if :delete_where not in unquote(no_alias) do
        @spec delete_where(keyword()) :: {non_neg_integer(), nil | [term()]}
        @doc """
        Delete all matching records
        ## Parameters
        - `params` Keyword list of `[{:column_name, value}]` to filter then delete all records by
        ## Returns
        - `result` This depends on the underlying database, see the ecto docs for `Ecto.Repo.delete_all`.
        """
        def delete_where(params), do: base_delete_where(params)
      end

      if :delete not in unquote(no_alias) do
        @spec delete(term) :: {non_neg_integer(), nil | [term()]}
        @doc """
        Delete a record by primary key
        ## Parameters
        - `id` The value of the record's primary key
        ## Returns
        - `result` This depends on the underlying database, see the ecto docs for `Ecto.Repo.delete_all`.
        """
        def delete(id), do: base_delete(id)
      end

      if :build_query not in unquote(no_alias) do
        @spec build_query(keyword()) :: ecto_query()
        @doc """
        Build an ecto query
        ## Parameters
        - `params` Keyword list of `[{:column_name, value}]` to filter all records by
        ## Returns
        - `query` The resulting ecto query
        """
        def build_query(params), do: base_build_query(params)
      end

      if :first not in unquote(no_alias) do
        @spec first(keyword()) :: {:ok, t()} | {:error, :not_found}
        @doc """
        Get the first matching record. The order is unspecified unless encoded in `params`.
        ## Parameters
        - `params` Keyword list of `[{:column_name, value}]` to filter all records by
        ## Returns
        - `{:ok, model}` All is well
        - `{:error, :not_found}` No matching record found
        """
        def first(params), do: base_first(params)
      end

      if :update_model not in unquote(no_alias) do
        @spec update_model(t()) :: {:ok, t()} | {:error, any()}
        @doc """
        Update a model; look it up first then apply the model
        parameter as a changeset
        ## Parameters
        - `model` The model; all deltas between `model` and the current
          database record will be updated from `model`.
        ## Returns
        - `{:ok, updated_model}` All is well, updated model came out of the db
        - `{:error, reason}` Failed for reason
        """
        def update_model(model), do: base_update_model(model)
      end
    end
  end
end
