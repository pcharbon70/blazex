defmodule BlazeX.Phoenix.OriginPolicyTest do
  use ExUnit.Case, async: true

  alias BlazeX.Phoenix.OriginPolicy

  test "accepts canonical same origins including default ports" do
    assert :ok = OriginPolicy.authorize(["https://EXAMPLE.com"], :https, "example.COM", 443)
    assert :ok = OriginPolicy.authorize(["http://example.com:4100"], "http", "example.com", 4100)
  end

  test "rejects absent, duplicate, and cross-origin values" do
    assert {:error, "origin-invalid"} = OriginPolicy.authorize([], :https, "example.com", 443)

    assert {:error, "origin-invalid"} =
             OriginPolicy.authorize(
               ["https://example.com", "https://example.com"],
               :https,
               "example.com",
               443
             )

    assert {:error, "origin-invalid"} =
             OriginPolicy.authorize(["https://other.example"], :https, "example.com", 443)
  end

  test "rejects non-web, opaque, malformed, and decorated origins" do
    invalid = [
      "null",
      "file:///tmp/demo",
      "ftp://example.com",
      "https://user@example.com",
      "https://example.com/",
      "https://example.com/path",
      "https://example.com?query",
      "https://example.com#fragment",
      "https://exa mple.com"
    ]

    for origin <- invalid do
      assert {:error, "origin-invalid"} =
               OriginPolicy.authorize([origin], :https, "example.com", 443)
    end
  end

  test "rejects invalid expected endpoint data" do
    assert {:error, "origin-invalid"} =
             OriginPolicy.authorize(["https://example.com"], :ws, "example.com", 443)

    assert {:error, "origin-invalid"} =
             OriginPolicy.authorize(["https://example.com"], :https, "", 443)

    assert {:error, "origin-invalid"} =
             OriginPolicy.authorize(["https://example.com"], :https, "example.com", 0)
  end
end
