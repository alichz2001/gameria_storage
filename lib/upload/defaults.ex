defmodule GameriaStorage.Upload.Defaults do

  def validate_file_type(%Ecto.Changeset{
    valid?: :true,
    data: %{acceptable_types: acceptable_types},
    changes: %{file_type: type}
  } = changeset) do
    if type in acceptable_types do
      changeset
    else
      changeset
      |> Ecto.Changeset.add_error(:file_type, "type not acceptable")
    end
  end
  def validate_file_type(changeset), do: changeset

  def put_file_data(%Ecto.Changeset{valid?: :true, changes: %{from_path: from_path, file_name: file_name}} = changeset) do
    changeset
    |> Ecto.Changeset.put_change(:file_type, Path.extname(file_name))
    |> Ecto.Changeset.put_change(:file_size, GameriaStorage.Utils.file_size(from_path, :B))
  end
  def put_file_data(%Ecto.Changeset{} = changeset), do: changeset


  # attrs = attrs
  # |> Map.put("file_size", GameriaStorage.Utils.file_size(attrs["from_path"], :B))
  # |> Map.put("file_type", Path.extname(attrs["file"].filename))
  # |> Map.put("from_path", attrs["file"].path)

end
