defmodule GameriaStorage.Upload.FuncGenerators do

  import GameriaStorage.Utils

  def gen_file_name_func(file_naming_strategy) do
    file_naming_strategy
    |> case do
      :custom -> []
      :default -> [quote do: def file_name(_struct), do: "default"]
      :random -> [quote do: def file_name(_struct), do: "random_name"]
      _ -> []
    end
  end

  def gen_upload_path_func(upload_path_strategy) do
    upload_path_strategy
    |> case do
      :custom -> []
      :default -> [quote do: def upload_path(%{uploader_key: uploader_key} = _struct), do: "/uploads/users/#{uploader_key}/"]
      _ -> []
    end
  end

  def gen_move_file_func(move_file_strategy) do
    move_file_strategy
    |> case do
      :custom -> []
      :replace ->
        [quote do
          def move_file(%{from_path: from_path, upload_path: upload_path, file_name: file_name, file_type: file_type} = struct) do
            with :ok <- File.mkdir_p(upload_path),
                 :ok <- File.cp(from_path, upload_path <> file_name <> file_type),
            do: {:ok, struct}
          end
        end]
      _ -> []
    end
  end

  def gen_size_limit_func(size_limit) do
    size_limit_ast =
      size_limit
      |> case do
        [duartion: [max: max, min: min]] ->
          [quote do
            defp validate_file_size(%Ecto.Changeset{valid?: :true, changes: %{file_size: file_size}} = changeset)
              when file_size < max and file_size > min, do: changeset
          end]
          |> Macro.prewalk(fn
            {:min, _, _} -> to_bytes(min)
            {:max, _, _} -> to_bytes(max)
            i -> i
          end)
        [max: max] ->
            [quote do
              defp validate_file_size(%Ecto.Changeset{valid?: :true, changes: %{file_size: file_size}} = changeset)
                when file_size < max, do: changeset
            end]
            |> Macro.prewalk(fn
              {:max, _, _} -> to_bytes(max)
              i -> i
            end)

        :none -> []
      end

    {:__block__, _, def_list} = quote do
      defp validate_file_size(%Ecto.Changeset{valid?: true} = changeset), do: changeset |> add_error(:file_size, "size not acceptable")
      defp validate_file_size(%Ecto.Changeset{} = changeset), do: changeset
    end
    size_limit_ast ++ def_list
  end

  def gen_guard_func(guard_module) do
    {:__block__, _, funcs} = quote do
      defp g_before_move_file(struct) do
        with {:roleback, reason, struct} <- GuardModule.before_move_file(struct) do
          GuardModule.roleback(:before_move_file, reason, struct)
        end
      end
      defp g_after_move_file(struct) do
        with {:roleback, reason, struct} <- GuardModule.after_move_file(struct) do
          GuardModule.roleback(:after_move_file, reason, struct)
        end
      end
    end
    |> Macro.prewalk(fn
      :GuardModule -> guard_module
      i -> i
    end)

    funcs
  end

end
