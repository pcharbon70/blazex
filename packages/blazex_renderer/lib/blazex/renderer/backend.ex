defmodule BlazeX.Renderer.Backend do
  @moduledoc """
  Behaviour implemented by concrete visual or nonvisual renderer backends.
  """

  alias BlazeX.Renderer.{Artifact, Capabilities, Context}

  @callback capabilities() :: Capabilities.t()
  @callback mount(term(), Context.t()) :: {:ok, term(), Artifact.t()} | {:error, term()}
  @callback update(term(), term(), Context.t()) :: {:ok, term(), Artifact.t()} | {:error, term()}
  @callback replace(term(), term(), Context.t()) :: {:ok, term(), Artifact.t()} | {:error, term()}
  @callback dispose(term(), Context.t()) :: {:ok, term(), Artifact.t()} | {:error, term()}
end
