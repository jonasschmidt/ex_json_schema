ExUnit.start()
HTTPoison.start()
{:ok, _} = :inets.start(:httpd, server_name: 'test 1', document_root: './test/JSON-Schema-Test-Suite/remotes', server_root: '.', port: 1234)
