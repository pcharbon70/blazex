alias BlazeX.NativeSpike.{Fixture, Wire}
alias BlazeX.Renderer.Session

case System.argv() do
  [mount_path, stale_path] ->
    {:ok, session} = Session.mount(BlazeX.NativeSpike, Fixture.intent_set!())
    mount = Wire.encode(session.artifact.value)
    stale = String.replace(mount, "\t0\tmount\t", "\t2\tupdate\t", global: false)
    File.write!(mount_path, mount)
    File.write!(stale_path, stale)

  _ ->
    raise "usage: mix run scripts/write_fixture.exs MOUNT_PATH STALE_PATH"
end
