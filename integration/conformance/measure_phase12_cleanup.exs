Code.require_file("../bh-05/browser_conformance/lib/acceptance_cleanup.ex", __DIR__)

result = BlazeX.BH05.Acceptance.Cleanup.run()

Enum.each(result["cleanup"], fn sample ->
  IO.puts(
    Enum.join(
      [
        "BH05_CLEANUP",
        sample["sample"],
        sample["elapsed_ms"],
        sample["requested"],
        sample["unresolved"],
        sample["forced"],
        sample["terminal_leases"],
        sample["late_results"]
      ],
      "\t"
    )
  )
end)

Enum.each(result["process_growth"], fn sample ->
  IO.puts(
    Enum.join(
      [
        "BH05_PROCESS",
        sample["sample"],
        sample["cycles"],
        sample["baseline"],
        sample["terminal"],
        sample["unexpected_growth"],
        sample["late_results"]
      ],
      "\t"
    )
  )
end)
