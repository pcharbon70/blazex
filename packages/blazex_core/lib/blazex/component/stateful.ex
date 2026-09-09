defmodule BlazeX.Component.Stateful do
  @moduledoc "Nested state belongs to its root, not an independent process."
  @callback init(map()) :: {:state, term()} | {:rejected, atom()}
  @callback render(map()) :: {:output, term()} | {:rejected, atom()}
  @callback update(map()) :: BlazeX.Component.Result.candidate()
  @callback handle_event(map()) :: BlazeX.Component.Result.candidate()
  @callback handle_info(map()) :: BlazeX.Component.Result.candidate()
  @callback replace(map()) :: BlazeX.Component.Result.candidate()
  @callback dispose(map()) :: :ok | {:rejected, atom()}
  @optional_callbacks update: 1, handle_event: 1, handle_info: 1, replace: 1, dispose: 1
end
