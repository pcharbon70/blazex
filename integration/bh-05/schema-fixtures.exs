defmodule BlazeX.BH05.SchemaCard do
  use BlazeX.Component,
    role: :pure,
    schema: [
      props: [
        {"title", [type: :string, required: true, doc: "Visible title"]},
        {"count", [type: {:custom, "count", 1, {:integer, 0, 10}}, default: 0]},
        {"pair",
         [type: {:tuple, [:string, :integer]}, default: ["a", 1], deprecated: "use named values"]}
      ],
      slots: [
        {"default",
         [
           boundary: :host,
           required: true,
           key: :required,
           props: [{"label", [type: :string, default: "item"]}],
           context: {:record, [{"selected", :boolean}]}
         ]}
      ]
    ]

  # Normalization and analysis must never call this body.
  def render(_input), do: :erlang.error(:component_body_must_not_execute)
end

defmodule BlazeX.BH05.SchemaLocal do
  use BlazeX.Component,
    role: :stateful,
    schema: [
      props: [{"callback", [type: {:callable, 1}, boundary: :local]}],
      slots: [{"default", [key: :optional, max: 2]}]
    ]

  def init(_input), do: :erlang.error(:component_body_must_not_execute)
  def render(_input), do: :erlang.error(:component_body_must_not_execute)
end

defmodule BlazeX.BH05.SchemaData do
  def normalize do
    metadata = BlazeX.BH05.SchemaCard.__blazex_component__()

    BlazeX.Component.Invocation.normalize(
      metadata.schema.declarations,
      %{"title" => "Example"},
      %{
        "default" => [
          %{
            "key" => "row",
            "context" => %{"selected" => true},
            "content" => %{"kind" => "text", "value" => "Content"}
          }
        ]
      },
      %{kind: :host, root: "example", owner: "adapter"}
    )
  end
end
