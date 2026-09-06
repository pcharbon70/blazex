defmodule BlazeX.NativeSpike.Gtk4PlatformTest do
  use ExUnit.Case, async: false

  @tag timeout: 30_000
  test "direct GTK adapter materializes and exercises the representative slice" do
    {output, status} =
      System.cmd("python3", ["scripts/run_gtk4.py"],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert status == 0, output
    assert String.contains?(output, ~s("result": "passed"))
    assert String.contains?(output, ~s("support_state": "experimental-unsupported"))
    assert length(Regex.scan(~r/"native_type": "Gtk/, output)) == 11
    assert String.contains?(output, ~s("native_type": "GtkFileDialog"))
    assert String.contains?(output, "stale_rejected=1")
    assert String.contains?(output, "disposals=1")
  end
end
