defmodule GameriaStorage.Upload do

  @moduledoc """
  This module implement all upload functionality of GameriaStorage
  """

  @callback custom_validations(changeset :: Ecto.Changeset) :: Ecto.Changeset
  @callback file_name(struct :: map()) :: String.t
  @callback upload_path(struct :: map()) :: String.t
  @callback move_file(struct :: map()) :: {:ok, struct :: map()} | {:error, reason :: atom()}
  @callback output(struct :: map()) :: any()

  @default_struct_items [
    acceptable_types: [], uploader_key: "", upload_token: "", file_size: 0, file_type: "", from_path: "",
    upload_path: "", file_name: ""
  ]
  @required_fields [
    :acceptable_types, :uploader_key, :upload_token, :from_path, :file_name
  ]

  alias GameriaStorage.Upload.{FuncGenerators, Defaults}

  defmacro __using__(opts) do

    size_limit = Keyword.get(opts, :size_limit) || raise "should set size_limit"
    parameters = Keyword.get(opts, :parameters, [])
    parameters_key_list = Keyword.keys(parameters)
    acceptable_types = Keyword.get(opts, :acceptable_file_types) || raise "should set acceptable_file_types"
    upload_token = Keyword.get(opts, :upload_token) || raise "should set upload_token"
    file_naming_strategy = Keyword.get(opts, :file_naming_strategy, :random)
    upload_path_strategy = Keyword.get(opts, :upload_path_strategy, :custom)
    move_file_strategy = Keyword.get(opts, :move_file_strategy, :custom)

    func_file_name_ast = FuncGenerators.gen_file_name_func(file_naming_strategy)
    func_upload_path_ast = FuncGenerators.gen_upload_path_func(upload_path_strategy)
    func_move_file_ast = FuncGenerators.gen_move_file_func(move_file_strategy)
    func_size_limit_ast = FuncGenerators.gen_size_limit_func(size_limit)

    {:__block__, metadata_list, ast} = quote location: :keep do
      @behaviour GameriaStorage.Upload
      import GameriaStorage.Upload
      import Ecto.Changeset

      Module.register_attribute(__MODULE__, :guard, persist: :false, accumulate: :false)

      defstruct (unquote(@default_struct_items)
        |> Keyword.put(:acceptable_types, unquote(acceptable_types))
        |> Keyword.put(:upload_token, unquote(upload_token))
      ) ++ unquote(parameters_key_list)

      @types %{
        acceptable_types: {:list, :string},
        uploader_key: :string,
        upload_token: :string,
        file_size: :integer,
        file_type: :string,
        from_path: :string,
        file_name: :string
      } |> Map.merge(Enum.into(unquote(parameters), %{}))

      def upload(attrs \\ %{}) do
        with {:ok, struct} <- g_changeset(attrs),
             {:ok, struct} <- g_after_validate(struct),
             {:ok, struct} <- g_before_move_file(struct),
             {:ok, struct} <- move_file(struct),
             {:ok, struct} <- g_after_move_file(struct),
             out           <- output(struct)
        do
          {:ok, out}
        end
      end

      defp g_base_changeset(attrs \\ %{}) do
        base = %__MODULE__{
          acceptable_types: unquote(acceptable_types),
          upload_token: unquote(upload_token)
        }

        {base, @types}
        |> Ecto.Changeset.cast(attrs, Map.keys(@types))
        |> Ecto.Changeset.validate_required(unquote(@required_fields))
        |> Defaults.put_file_data()
        |> Defaults.validate_file_type()
        |> validate_file_size()
      end

      def upload_token(), do: unquote(upload_token)

      @before_compile unquote(__MODULE__)
    end
    {:__block__, metadata_list, ast ++ func_file_name_ast ++ func_upload_path_ast ++ func_move_file_ast ++ func_size_limit_ast}
  end
  defmacro __before_compile__(env) do
    {:__block__, metadata, ast} = quote do
      def custom_validations(changeset), do: changeset
      def roleback(_, _reason, struct), do: {:ok, struct}
      def before_move_file(struct), do: {:ok, struct}
      def after_move_file(struct), do: {:ok, struct}
      def output(struct), do: struct

      defp g_changeset(attrs) do
        g_base_changeset(attrs)
        |> custom_validations()
        |> Ecto.Changeset.apply_action(:upload)
      end

      defp g_after_validate(struct) do
        struct = struct
        |> Map.put(:file_name, file_name(struct))
        |> Map.put(:upload_path, upload_path(struct))
        {:ok, struct}
      end
    end

    guard_module = Module.get_attribute(env.module, :guard, GameriaStorage.Guard.Default)
    guard_ast = FuncGenerators.gen_guard_func(guard_module)

    {:__block__, metadata, ast ++ guard_ast}
  end

  defmacro guard(guard_module) do
    quote do
      Module.put_attribute(__MODULE__, :guard, unquote(guard_module))
    end
  end
end
