defmodule GameriaStorage.Guard do

  @callback before_move_file(map()) ::
    {:ok, struct} |
    {:error, reason :: atom(), struct} |
    {:roleback, reason :: atom(), struct}
  @callback after_move_file(map()) ::
    {:ok, struct} |
    {:error, reason :: atom(), struct} |
    {:roleback, reason :: atom(), struct}
  @callback roleback(role_bask_step :: atom(), reason :: atom(), struct :: map()) :: {:ok, struct :: map()}

end
