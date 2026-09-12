defmodule BlazeX.Build.ClientClosure do
  @moduledoc "Orders client-safety authorization before candidate assembly."

  alias BlazeX.Build.{
    ClientSafety,
    ClientSafetyPolicy,
    Compatibility,
    CompatibilityProfile,
    CompatibilityRequirements
  }

  def authorize!(reachability, inventory, %ClientSafetyPolicy{} = policy, assemble)
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    {safety, assemble.(safety)}
  end

  def authorize!(_, _, _, _),
    do: raise(ArgumentError, "client closure requires a validated policy and arity-one assembler")

  def authorize!(
        reachability,
        inventory,
        %ClientSafetyPolicy{} = policy,
        %CompatibilityProfile{} = profile,
        %CompatibilityRequirements{} = requirements,
        assemble
      )
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    compatibility = Compatibility.evaluate!(profile, requirements)
    authorization = %{"client_safety" => safety, "compatibility" => compatibility}
    {safety, compatibility, assemble.(authorization)}
  end

  def authorize!(_, _, _, _, _, _),
    do:
      raise(
        ArgumentError,
        "client closure requires validated safety and compatibility inputs plus an arity-one assembler"
      )
end
