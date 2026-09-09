defmodule BlazeX.Component.Root do
  @moduledoc "Process-root contract only. Process startup is deferred to Phase 6."
  @callback mount(map()) :: {:state, term()} | {:rejected, atom()}
  @callback render(map()) :: {:output, term()} | {:rejected, atom()}
  @callback update(map()) :: term()
  @callback handle_event(map()) :: term()
  @callback handle_info(map()) :: term()
  @callback commit_ack(map()) :: term()
  @callback effect_result(map()) :: term()
  @callback failure(map()) :: term()
  @callback retry(map()) :: term()
  @callback replace(map()) :: term()
  @callback terminate(map()) :: :ok | {:rejected, atom()}
  @optional_callbacks update: 1,
                      handle_event: 1,
                      handle_info: 1,
                      commit_ack: 1,
                      effect_result: 1,
                      failure: 1,
                      retry: 1,
                      replace: 1,
                      terminate: 1
end
