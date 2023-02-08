defmodule GameriaStorage.Utils do
  def file_size(file_path, vol \\ :KB) do
    %{size: size} = File.stat!(file_path)
    div(size, vol(vol))
  end

  defp vol(:B), do: 1
  defp vol(:KB), do: 1024
  defp vol(:MB), do: 1024_000

  def to_kb({i, :KB}), do: i
  def to_kb({i, :MB}), do: i * 1_000
  def to_kb({i, :GB}), do: i * 1_000_000

  def to_bytes({i, :B}), do: i
  def to_bytes({i, :KB}), do: i * 1_000
  def to_bytes({i, :MB}), do: i * 1_000_000
  def to_bytes({i, :GB}), do: i * 1_000_000_000
end
