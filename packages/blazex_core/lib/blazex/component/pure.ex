defmodule BlazeX.Component.Pure do
  @moduledoc "Caller-evaluated pure component; no retained state or mailbox."
  @callback render(map()) :: {:output, term()} | {:rejected, atom()}
end
