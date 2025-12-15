defmodule SamplePhoenix.SampleController do
  use Phoenix.Controller, formats: [json: "View"]

  def show(conn, %{"path" => path}) do
    test_path = Path.join(__DIR__, "..") |> Path.expand()

    json =
      case File.read(Path.join([test_path, "support/schemata"] ++ path)) do
        {:ok, json} -> json
        _ -> File.read!(Path.join([test_path, "JSON-Schema-Test-Suite/remotes"] ++ path))
      end

    conn |> put_resp_content_type("application/json") |> send_resp(200, json)
  end
end

defmodule Router do
  use Phoenix.Router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", SamplePhoenix, log: false do
    pipe_through(:api)

    get("/*path", SampleController, :show)
  end
end

defmodule SamplePhoenix.Endpoint do
  use Phoenix.Endpoint, otp_app: :ex_json_schema
  plug(Router)
end
