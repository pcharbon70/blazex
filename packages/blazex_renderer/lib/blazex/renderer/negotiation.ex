defmodule BlazeX.Renderer.Negotiation do
  @moduledoc """
  Deny-by-default renderer compatibility result.
  """

  alias BlazeX.Renderer.{Capabilities, Diagnostic, Requirements}

  @enforce_keys [:capabilities, :requirements]
  defstruct [:capabilities, :requirements]

  @type t :: %__MODULE__{capabilities: Capabilities.t(), requirements: Requirements.t()}

  @spec negotiate(Capabilities.t(), Requirements.t(), module() | nil) ::
          {:ok, t()} | {:error, Diagnostic.t()}
  def negotiate(capabilities, requirements, backend \\ nil)

  def negotiate(%Capabilities{} = capabilities, %Requirements{} = requirements, backend) do
    with :ok <- validate_capabilities(capabilities, backend),
         :ok <-
           require_member(
             requirements.tree_version,
             capabilities.tree_versions,
             :tree_version,
             backend
           ),
         :ok <-
           require_subset(requirements.node_kinds, capabilities.node_kinds, :node_kinds, backend),
         :ok <-
           require_subset(
             requirements.layout_modes,
             capabilities.layout_modes,
             :layout_modes,
             backend
           ),
         :ok <-
           require_subset(
             requirements.accessibility_roles,
             capabilities.accessibility_roles,
             :accessibility_roles,
             backend
           ),
         :ok <- require_subset(requirements.features, capabilities.features, :features, backend) do
      {:ok, %__MODULE__{capabilities: capabilities, requirements: requirements}}
    end
  end

  def negotiate(_capabilities, _requirements, backend),
    do: diagnostic(:invalid_negotiation, :negotiate, backend, :malformed_input)

  defp validate_capabilities(capabilities, backend) do
    case Capabilities.validate(capabilities) do
      :ok -> :ok
      {:error, reason} -> diagnostic(:invalid_capabilities, :negotiate, backend, reason)
    end
  end

  defp require_member(required, supported, field, backend) do
    if required in supported,
      do: :ok,
      else: diagnostic(:missing_renderer_capability, :negotiate, backend, %{field => [required]})
  end

  defp require_subset(required, supported, field, backend) do
    missing = Enum.reject(required, &(&1 in supported))

    if missing == [],
      do: :ok,
      else: diagnostic(:missing_renderer_capability, :negotiate, backend, %{field => missing})
  end

  defp diagnostic(code, stage, backend, detail),
    do: {:error, %Diagnostic{code: code, stage: stage, backend: backend, detail: detail}}
end
