defmodule BlazeX.Core.Component do
  @moduledoc """
  Experimental callback contract for host-neutral component evaluation.

  Pure components implement `render/2`. Stateful components implement
  `init/2`, `update/3`, and `render/3`. Every callback returns `{:ok, value}` or
  `{:error, reason}`; reasons are intentionally not retained in public
  diagnostics because they may contain opaque or sensitive terms.
  """

  alias BlazeX.Core.{Context, Event}

  @type mode :: :pure | :stateful
  @type props :: map()
  @type state :: term()
  @type output :: term()

  @callback mode() :: mode()
  @callback render(props(), Context.t()) :: {:ok, output()} | {:error, term()}
  @callback init(props(), Context.t()) :: {:ok, state()} | {:error, term()}
  @callback update(props(), state(), Context.t()) :: {:ok, state()} | {:error, term()}
  @callback render(props(), state(), Context.t()) :: {:ok, output()} | {:error, term()}
  @callback handle_event(Event.t(), props(), state(), Context.t()) ::
              {:ok, state(), [term()]} | {:error, term()}

  @optional_callbacks render: 2, init: 2, update: 3, render: 3, handle_event: 4
end
