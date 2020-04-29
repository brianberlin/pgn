defmodule PostgresPgnotify.Repo do
  use Ecto.Repo,
    otp_app: :postgres_pgnotify,
    adapter: Ecto.Adapters.Postgres
end
