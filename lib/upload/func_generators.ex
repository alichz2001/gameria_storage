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
          [{:defp, [context: GameriaStorage, imports: [{1, Kernel}, {2, Kernel}]],
            [
              {:when, [context: GameriaStorage],
                [
                  {:validate_file_size, [],
                  [
                    {:=, [],
                      [
                        {:%, [],
                        [
                          {:__aliases__, [alias: false], [:Ecto, :Changeset]},
                          {:%{}, [],
                            [
                              valid?: true,
                              changes: {:%{}, [],
                              [file_size: {:file_size, [], GameriaStorage}]}
                            ]}
                        ]},
                        {:changeset, [], GameriaStorage}
                      ]}
                  ]},
                  {:and, [context: GameriaStorage, imports: [{2, Kernel}]],
                  [
                    {:>, [context: GameriaStorage, imports: [{2, Kernel}]],
                      [{:file_size, [], GameriaStorage}, to_bytes(min)]},
                    {:<, [context: GameriaStorage, imports: [{2, Kernel}]],
                      [{:file_size, [], GameriaStorage}, to_bytes(max)]}
                  ]}
                ]},
              [do: {:changeset, [], GameriaStorage}]
            ]}]
        [max: max] ->
          [{:defp, [context: GameriaStorage, imports: [{1, Kernel}, {2, Kernel}]],
            [
              {:when, [context: GameriaStorage],
                [
                  {:validate_file_size, [],
                  [
                    {:=, [],
                      [
                        {:%, [],
                        [
                          {:__aliases__, [alias: false], [:Ecto, :Changeset]},
                          {:%{}, [],
                            [
                              valid?: true,
                              changes: {:%{}, [],
                              [file_size: {:file_size, [], GameriaStorage}]}
                            ]}
                        ]},
                        {:changeset, [], GameriaStorage}
                      ]}
                  ]},
                  {:<, [context: GameriaStorage, imports: [{2, Kernel}]],
                  [{:file_size, [], GameriaStorage}, to_bytes(max)]}
                ]},
              [do: {:changeset, [], GameriaStorage}]
            ]}]
        :none -> []
      end

    {:__block__, _, def_list} = quote do
      defp validate_file_size(%Ecto.Changeset{valid?: true} = changeset), do: changeset |> add_error(:file_size, "size not acceptable")
      defp validate_file_size(%Ecto.Changeset{} = changeset), do: changeset
    end
    size_limit_ast ++ def_list
  end

  def gen_guard_func(guard_module) do
    guard_atom = guard_module
    |> Module.split()
    |> List.last()
    |> String.to_atom()

    [
      {:defp, [context: GameriaStorage.Upload, imports: [{1, Kernel}, {2, Kernel}]],
        [
          {:g_after_move_file, [context: GameriaStorage.Upload],
            [
              {:struct,
              [context: GameriaStorage.Upload, imports: [{1, Kernel}, {2, Kernel}]],
              GameriaStorage.Upload}
            ]},
          [
            do: {:with, [],
              [
                {:<-, [],
                [
                  {:{}, [],
                    [
                      :roleback,
                      {:reason, [], GameriaStorage.Upload},
                      {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                    ]},
                  {{:., [],
                    [
                      {:__aliases__, [alias: guard_module],
                        [guard_atom]},
                      :after_move_file
                    ]}, [],
                    [
                      {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                    ]}
                ]},
                [
                  do: {{:., [],
                    [
                      {:__aliases__, [alias: guard_module],
                      [guard_atom]},
                      :roleback
                    ]}, [],
                  [
                    :after_move_file,
                    {:reason, [], GameriaStorage.Upload},
                    {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                  ]}
                ]
              ]}
          ]
        ]},
        {:defp, [context: GameriaStorage.Upload, imports: [{1, Kernel}, {2, Kernel}]],
        [
          {:g_before_move_file, [context: GameriaStorage.Upload],
            [
              {:struct,
              [context: GameriaStorage.Upload, imports: [{1, Kernel}, {2, Kernel}]],
              GameriaStorage.Upload}
            ]},
          [
            do: {:with, [],
              [
                {:<-, [],
                [
                  {:{}, [],
                    [
                      :roleback,
                      {:reason, [], GameriaStorage.Upload},
                      {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                    ]},
                  {{:., [],
                    [
                      {:__aliases__, [alias: guard_module],
                        [guard_atom]},
                      :before_move_file
                    ]}, [],
                    [
                      {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                    ]}
                ]},
                [
                  do: {{:., [],
                    [
                      {:__aliases__, [alias: guard_module],
                      [guard_atom]},
                      :roleback
                    ]}, [],
                  [
                    :before_move_file,
                    {:reason, [], GameriaStorage.Upload},
                    {:struct,
                      [
                        context: GameriaStorage.Upload,
                        imports: [{1, Kernel}, {2, Kernel}]
                      ], GameriaStorage.Upload}
                  ]}
                ]
              ]}
          ]
        ]}
    ]
  end

end
