defmodule Rumbl.VideoTest do
  use Rumbl.ModelCase
  alias Rumbl.Video

  @valid_attrs %{description: "some content", title: "some content", url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Video.changeset(%Video{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Video.changeset(%Video{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset generates slug" do
    changeset = Video.changeset(%Video{}, @valid_attrs)
    assert changeset.changes.slug == "some-content"
  end
end

defmodule Rumbl.VideoParamProtocolTest do
  use Rumbl.ModelCase
  alias Rumbl.Video

  test ".to_param" do
    video = %Video{id: 123, slug: "hello-world"}
    assert Video.to_param(video) == "123-hello-world"
  end

  test "video  as route" do
    video = %Video{id: 123, slug: "hello-world"}
    watch_path_result = Rumbl.Router.Helpers.watch_path(%URI{}, :show, video)
    assert watch_path_result == "/watch/123-hello-world"
  end

  @doc """
  this is just different way  of "video as route" test
  """
  test "video as route using values defined in configuration files" do
    video = %Video{id: 123, slug: "hello-world"}
    url = Rumbl.Endpoint.struct_url
    assert Rumbl.Router.Helpers.watch_url(url, :show, video) == "http://localhost:4001/watch/123-hello-world"
  end

end
