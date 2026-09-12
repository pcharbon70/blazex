defmodule BlazeX.Build.ClientClosure do
  @moduledoc "Orders client-safety authorization before candidate assembly."

  alias BlazeX.Build.{ClientSafety, ClientSafetyPolicy}

  def authorize!(reachability, inventory, %ClientSafetyPolicy{} = policy, assemble)
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    {safety, assemble.(safety)}
  end

  def authorize!(_, _, _, _),
    do: raise(ArgumentError, "client closure requires a validated policy and arity-one assembler")
end
