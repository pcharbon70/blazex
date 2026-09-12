defmodule BlazeX.Build.ClientClosure do
  @moduledoc "Orders client-safety authorization before candidate assembly."

  alias BlazeX.Build.{
    BundlePlan,
    BundlePolicy,
    ClientSafety,
    ClientSafetyPolicy,
    Compatibility,
    CompatibilityProfile,
    CompatibilityRequirements,
    LicenseInventory,
    LicensePolicy,
    SecretAudit,
    SecretPolicy
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

  def authorize!(
        reachability,
        inventory,
        %ClientSafetyPolicy{} = policy,
        %CompatibilityProfile{} = profile,
        %CompatibilityRequirements{} = requirements,
        %SecretPolicy{} = secret_policy,
        secret_inputs,
        public_config,
        assemble
      )
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    compatibility = Compatibility.evaluate!(profile, requirements)
    secret_audit = SecretAudit.analyze!(secret_inputs, public_config, secret_policy)

    authorization = %{
      "client_safety" => safety,
      "compatibility" => compatibility,
      "secret_audit" => secret_audit
    }

    {safety, compatibility, secret_audit, assemble.(authorization)}
  end

  def authorize!(_, _, _, _, _, _, _, _, _),
    do:
      raise(
        ArgumentError,
        "client closure requires validated safety, compatibility, and secret-audit inputs plus an arity-one assembler"
      )

  def authorize!(
        reachability,
        inventory,
        %ClientSafetyPolicy{} = policy,
        %CompatibilityProfile{} = profile,
        %CompatibilityRequirements{} = requirements,
        %SecretPolicy{} = secret_policy,
        secret_inputs,
        public_config,
        %LicensePolicy{} = license_policy,
        license_inputs,
        repository_root,
        assemble
      )
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    compatibility = Compatibility.evaluate!(profile, requirements)
    secret_audit = SecretAudit.analyze!(secret_inputs, public_config, secret_policy)
    license_inventory = LicenseInventory.analyze!(license_inputs, license_policy, repository_root)
    :ok = LicenseInventory.assert_matches_secret_audit!(license_inventory, secret_audit)

    authorization = %{
      "client_safety" => safety,
      "compatibility" => compatibility,
      "secret_audit" => secret_audit,
      "license_inventory" => license_inventory
    }

    {safety, compatibility, secret_audit, license_inventory, assemble.(authorization)}
  end

  def authorize!(_, _, _, _, _, _, _, _, _, _, _, _),
    do:
      raise(
        ArgumentError,
        "client closure requires validated safety, compatibility, secret-audit, and license-inventory inputs plus an arity-one assembler"
      )

  def authorize!(
        reachability,
        inventory,
        %ClientSafetyPolicy{} = policy,
        %CompatibilityProfile{} = profile,
        %CompatibilityRequirements{} = requirements,
        %SecretPolicy{} = secret_policy,
        secret_inputs,
        public_config,
        %LicensePolicy{} = license_policy,
        license_inputs,
        repository_root,
        %BundlePolicy{} = bundle_policy,
        bundle_inputs,
        assemble
      )
      when is_function(assemble, 1) do
    safety = ClientSafety.analyze!(reachability, inventory, policy)
    compatibility = Compatibility.evaluate!(profile, requirements)
    secret_audit = SecretAudit.analyze!(secret_inputs, public_config, secret_policy)
    license_inventory = LicenseInventory.analyze!(license_inputs, license_policy, repository_root)
    :ok = LicenseInventory.assert_matches_secret_audit!(license_inventory, secret_audit)
    bundle_plan = BundlePlan.plan!(bundle_inputs, bundle_policy)

    authorization = %{
      "client_safety" => safety,
      "compatibility" => compatibility,
      "secret_audit" => secret_audit,
      "license_inventory" => license_inventory,
      "bundle_plan" => bundle_plan
    }

    {safety, compatibility, secret_audit, license_inventory, bundle_plan,
     assemble.(authorization)}
  end

  def authorize!(_, _, _, _, _, _, _, _, _, _, _, _, _, _),
    do:
      raise(
        ArgumentError,
        "client closure requires validated safety, compatibility, secret-audit, license-inventory, and bundle-plan inputs plus an arity-one assembler"
      )
end
