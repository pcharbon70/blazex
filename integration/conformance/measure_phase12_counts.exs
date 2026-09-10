Code.require_file("../bh-05/browser_conformance/lib/acceptance_counts.ex", __DIR__)

BlazeX.BH05.Acceptance.Counts.run()
|> Map.fetch!("samples")
|> Enum.each(fn sample ->
  backlog = sample["event_backlog"]
  pending = sample["pending_effects"]
  leases = sample["resource_leases"]
  restart = sample["restart_intensity"]

  IO.puts(
    Enum.join(
      [
        "BH05_COUNT",
        sample["sample"],
        backlog["maximum"],
        backlog["rejected"],
        pending["maximum"],
        pending["rejected"],
        leases["maximum"],
        leases["released"],
        leases["terminal"],
        restart["maximum"],
        restart["terminal"],
        restart["replayed"]
      ],
      "\t"
    )
  )
end)
