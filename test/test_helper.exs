ExUnit.start()
HTTPoison.start()

{:ok, _} = Supervisor.start_link([SamplePhoenix.Endpoint], strategy: :one_for_one)
