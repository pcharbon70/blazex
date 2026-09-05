defmodule BlazeX.Renderer.Session do
  @moduledoc """
  Immutable renderer lifecycle session with fail-closed ownership checks.
  """

  alias BlazeX.Core.Identity
  alias BlazeX.Renderer.{Artifact, Capabilities, Context, Diagnostic, Negotiation, Requirements}
  alias BlazeX.UITree.{Document, IntentSet, Node}

  @callbacks [:capabilities, :mount, :update, :replace, :dispose]
  @enforce_keys [
    :backend,
    :capabilities,
    :requirements,
    :owner,
    :generation,
    :revision,
    :status,
    :backend_state,
    :artifact
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          backend: module(),
          capabilities: Capabilities.t(),
          requirements: Requirements.t(),
          owner: Identity.t(),
          generation: pos_integer(),
          revision: non_neg_integer(),
          status: :mounted | :disposed,
          backend_state: term(),
          artifact: Artifact.t()
        }

  @spec mount(module(), term()) :: {:ok, t()} | {:error, Diagnostic.t()}
  def mount(backend, output) do
    with :ok <- validate_backend(backend),
         {:ok, owner} <- output_owner(output, backend, :mount),
         {:ok, requirements} <- derive_requirements(output, backend, :mount),
         {:ok, capabilities} <- backend_capabilities(backend),
         {:ok, _negotiation} <- Negotiation.negotiate(capabilities, requirements, backend),
         {:ok, context} <- context(owner, 0, :mount, backend),
         {:ok, backend_state, artifact} <- callback(backend, :mount, [output, context]) do
      {:ok,
       %__MODULE__{
         backend: backend,
         capabilities: capabilities,
         requirements: requirements,
         owner: owner,
         generation: owner.generation,
         revision: 0,
         status: :mounted,
         backend_state: backend_state,
         artifact: artifact
       }}
    end
  end

  @spec update(t(), term()) :: {:ok, t()} | {:error, Diagnostic.t()}
  def update(%__MODULE__{status: :mounted} = session, output) do
    revision = session.revision + 1

    with {:ok, owner} <- output_owner(output, session.backend, :update),
         :ok <- same_owner(owner, session, :update),
         {:ok, requirements} <- derive_requirements(output, session.backend, :update),
         {:ok, _negotiation} <-
           Negotiation.negotiate(session.capabilities, requirements, session.backend),
         {:ok, context} <- context(owner, revision, :update, session.backend),
         {:ok, backend_state, artifact} <-
           callback(session.backend, :update, [session.backend_state, output, context]) do
      {:ok,
       %{
         session
         | requirements: requirements,
           revision: revision,
           backend_state: backend_state,
           artifact: artifact
       }}
    end
  end

  def update(%__MODULE__{} = session, _output),
    do: diagnostic(:session_disposed, :update, session.backend, nil)

  def update(_session, _output), do: diagnostic(:invalid_session, :update, nil, nil)

  @spec replace(t(), term()) :: {:ok, t()} | {:error, Diagnostic.t()}
  def replace(%__MODULE__{status: :mounted} = session, output) do
    with {:ok, owner} <- output_owner(output, session.backend, :replace),
         :ok <- next_owner(owner, session),
         {:ok, requirements} <- derive_requirements(output, session.backend, :replace),
         {:ok, _negotiation} <-
           Negotiation.negotiate(session.capabilities, requirements, session.backend),
         {:ok, context} <- context(owner, 0, :replace, session.backend),
         {:ok, backend_state, artifact} <-
           callback(session.backend, :replace, [session.backend_state, output, context]) do
      {:ok,
       %{
         session
         | requirements: requirements,
           owner: owner,
           generation: owner.generation,
           revision: 0,
           backend_state: backend_state,
           artifact: artifact
       }}
    end
  end

  def replace(%__MODULE__{} = session, _output),
    do: diagnostic(:session_disposed, :replace, session.backend, nil)

  def replace(_session, _output), do: diagnostic(:invalid_session, :replace, nil, nil)

  @spec dispose(t()) :: {:ok, t()} | {:error, Diagnostic.t()}
  def dispose(%__MODULE__{status: :disposed} = session), do: {:ok, session}

  def dispose(%__MODULE__{status: :mounted} = session) do
    with {:ok, context} <- context(session.owner, session.revision, :dispose, session.backend),
         {:ok, backend_state, artifact} <-
           callback(session.backend, :dispose, [session.backend_state, context]) do
      {:ok, %{session | status: :disposed, backend_state: backend_state, artifact: artifact}}
    end
  end

  def dispose(_session), do: diagnostic(:invalid_session, :dispose, nil, nil)

  defp validate_backend(backend) when is_atom(backend) and not is_nil(backend) do
    if Code.ensure_loaded?(backend) and
         Enum.all?(@callbacks, &function_exported?(backend, &1, callback_arity(&1))) do
      :ok
    else
      diagnostic(:invalid_backend, :mount, backend, :missing_callback)
    end
  end

  defp validate_backend(backend), do: diagnostic(:invalid_backend, :mount, backend, :malformed)

  defp callback_arity(:capabilities), do: 0
  defp callback_arity(:mount), do: 2
  defp callback_arity(:update), do: 3
  defp callback_arity(:replace), do: 3
  defp callback_arity(:dispose), do: 2

  defp backend_capabilities(backend) do
    try do
      case backend.capabilities() do
        %Capabilities{} = capabilities ->
          case Capabilities.validate(capabilities) do
            :ok -> {:ok, capabilities}
            {:error, reason} -> diagnostic(:invalid_capabilities, :mount, backend, reason)
          end

        _other ->
          diagnostic(:invalid_capabilities, :mount, backend, :malformed)
      end
    rescue
      _exception -> diagnostic(:backend_failed, :capabilities, backend, :capabilities)
    catch
      _kind, _reason -> diagnostic(:backend_failed, :capabilities, backend, :capabilities)
    end
  end

  defp callback(backend, operation, arguments) do
    try do
      case apply(backend, operation, arguments) do
        {:ok, backend_state, %Artifact{} = artifact} ->
          if Artifact.valid?(artifact),
            do: {:ok, backend_state, artifact},
            else: diagnostic(:invalid_artifact, operation, backend, :invalid_envelope)

        {:error, _private_reason} ->
          diagnostic(:backend_rejected, operation, backend, operation)

        _other ->
          diagnostic(:invalid_backend_result, operation, backend, operation)
      end
    rescue
      _exception -> diagnostic(:backend_failed, operation, backend, operation)
    catch
      _kind, _reason -> diagnostic(:backend_failed, operation, backend, operation)
    end
  end

  defp output_owner(%Node{} = node, backend, stage) do
    case Node.validate(node) do
      :ok -> {:ok, node.identity}
      {:error, reason} -> diagnostic(:invalid_semantic_output, stage, backend, reason.code)
    end
  end

  defp output_owner(%Document{} = document, backend, stage) do
    case Document.validate(document) do
      :ok -> {:ok, document.root.identity}
      {:error, reason} -> diagnostic(:invalid_semantic_output, stage, backend, reason)
    end
  end

  defp output_owner(%IntentSet{} = intent_set, backend, stage) do
    case IntentSet.validate(intent_set) do
      :ok -> {:ok, intent_set.document.root.identity}
      {:error, reason} -> diagnostic(:invalid_semantic_output, stage, backend, reason)
    end
  end

  defp output_owner(_output, backend, stage),
    do: diagnostic(:invalid_semantic_output, stage, backend, :malformed)

  defp derive_requirements(output, backend, stage) do
    case Requirements.derive(output) do
      {:ok, requirements} -> {:ok, requirements}
      {:error, reason} -> diagnostic(:invalid_semantic_output, stage, backend, reason)
    end
  end

  defp same_owner(owner, session, stage) do
    if owner == session.owner,
      do: :ok,
      else: diagnostic(:renderer_owner_mismatch, stage, session.backend, nil)
  end

  defp next_owner(owner, session) do
    current = session.owner

    if owner.root == current.root and owner.path == current.path and
         owner.generation == current.generation + 1 do
      :ok
    else
      diagnostic(:invalid_renderer_replacement, :replace, session.backend, nil)
    end
  end

  defp context(owner, revision, transition, backend) do
    case Context.new(owner, revision, transition) do
      {:ok, context} -> {:ok, context}
      {:error, reason} -> diagnostic(:invalid_renderer_context, transition, backend, reason)
    end
  end

  defp diagnostic(code, stage, backend, detail),
    do: {:error, %Diagnostic{code: code, stage: stage, backend: backend, detail: detail}}
end
