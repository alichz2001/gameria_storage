defmodule GameriaStorage.Guard.Default do
  @behaviour GameriaStorage.Guard

  @impl GameriaStorage.Guard
  def before_move_file(struct), do: {:ok, struct}

  @impl GameriaStorage.Guard
  def after_move_file(struct), do: {:ok, struct}

  @impl GameriaStorage.Guard
  def roleback(_step, _reason, struct), do: {:ok, struct}
end
