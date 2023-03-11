defmodule GameriaStorage.Controller do
  alias GameriaStorage.Upload
  @callback upload_token(upload_token :: atom(), conn :: Plug.Conn.t(), params :: map()) :: any()
  @callback render_upload(
              upload_token :: atom(),
              conn :: Plug.Conn.t(),
              params :: map(),
              uploader_output :: any()
            ) :: Plug.Conn.t()

  defmacro __using__(opts) do
    upload_modules =
      Keyword.get(opts, :upload_modules) || raise "should set upload_modules in controller"

    web_module =
      __CALLER__.module
      |> Module.split()
      |> List.first()
      |> String.to_atom()

    use_ast = [quote do
      use WebModule, :controller
    end]
    # |> IO.inspect()
    |> Macro.prewalk(fn
      # i -> i |> IO.inspect()
      :WebModule -> web_module
      i -> i
    end)

    {:__block__, [], ast} =
      quote do
        @behaviour GameriaStorage.Controller
        @before_compile unquote(__MODULE__)
      end

    module_attr_ast = [
      {{:., [], [{:__aliases__, [alias: false], [:Module]}, :register_attribute]}, [],
       [
         {:__aliases__, [alias: false], __CALLER__.module},
         :upload_modules,
         [accumulate: false, persist: false]
       ]},
      {{:., [], [{:__aliases__, [alias: false], [:Module]}, :put_attribute]}, [],
       [
         {:__aliases__, [alias: false], __CALLER__.module},
         :upload_modules,
         upload_modules
       ]}
    ]

    # {:__block__, _, module_attr_ast} =
    #   quote do
    #     Module.register_attribute(CallerModule, :upload_modules, persist: :false, accumulate: :false)
    #     Module.put_attribute(CallerModule, :upload_modules, UploadModules)
    #   end
    #   |> Macro.prewalk(fn
    #     :CallerModule -> __CALLER__.module
    #     :UploadModules -> upload_modules
    #     i -> i
    #   end)
    #   |> IO.inspect()


    {:__block__, [], use_ast ++ module_attr_ast ++ ast}
  end

  defmacro __before_compile__(env) do
    upload_ast =
      Module.get_attribute(env.module, :upload_modules)
      |> IO.inspect()
      |> Enum.map(fn module ->
        quote do
          def upload(conn, %{"upload_token" => unquote(module.upload_token)} = params) do
            with {:ok, input} <-
                   upload_token(String.to_atom(unquote(module.upload_token)), conn, params),
                 {:ok, output} <- unquote(module).upload(input) do
              render_upload(String.to_atom(unquote(module.upload_token)), conn, params, output)
            end
          end
        end
      end)

    {:__block__, [], catch_all_ast} =
      quote do
        def upload(_conn, _params), do: {:error, :upload_token_not_found}
        def upload_token(_upload_token, _conn, _param), do: {:error, :not_found}

        def render_upload(_upload_token, conn, _params, out),
          do: conn |> put_status(:created) |> json(out)
      end

    {:__block__, [], upload_ast ++ catch_all_ast}
  end
end
