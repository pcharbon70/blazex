defmodule BlazeX.Component.Root do
  @moduledoc "Process-root contract only. Process startup is deferred to Phase 6."
  @callback mount(map()) :: {:state, term()} | {:rejected, atom()}
  @callback render(map()) :: {:output, term()} | {:rejected, atom()}
  @callback update(map()) :: BlazeX.Component.Result.candidate()
  @callback handle_event(map()) :: BlazeX.Component.Result.candidate()
  @callback handle_info(map()) :: BlazeX.Component.Result.candidate()
  @callback commit_ack(map()) :: BlazeX.Component.Result.candidate()
  @callback effect_result(map()) :: BlazeX.Component.Result.candidate()
  @callback failure(map()) :: BlazeX.Component.Result.candidate()
  @callback retry(map()) :: BlazeX.Component.Result.candidate()
  @callback replace(map()) :: BlazeX.Component.Result.candidate()
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
