defmodule BlazeX.Core.Authoring do
  @moduledoc false
  alias BlazeX.Component.{Contract, Input}
  @options [:role, :props, :slots, :capabilities, :registry, :context, :schema]

  def declare!(environment, options) do
    options =
      if Macro.quoted_literal?(options),
        do: elem(Code.eval_quoted(options), 0),
        else: fail!(:invalid_declaration)

    valid =
      Keyword.keyword?(options) and
        Enum.all?(Keyword.keys(options), &(&1 in @options)) and
        length(Keyword.keys(options)) == length(Enum.uniq(Keyword.keys(options))) and
        Keyword.get(options, :role) in Contract.roles() and
        Enum.all?(@options -- [:role, :schema], &Input.names?(Keyword.get(options, &1, [])))

    if not valid or Module.has_attribute?(environment.module, :blazex_authoring),
      do: fail!(:invalid_declaration)

    metadata = Map.new(options)

    if Map.has_key?(metadata, :schema) do
      if Map.has_key?(metadata, :props) or Map.has_key?(metadata, :slots),
        do: fail!(:ambiguous_schema)

      validate_schema!(metadata.schema)
    end

    Module.put_attribute(environment.module, :blazex_authoring, metadata)

    behaviour =
      case metadata.role do
        :pure -> BlazeX.Component.Pure
        :stateful -> BlazeX.Component.Stateful
        :root -> BlazeX.Component.Root
      end

    quote do
      @behaviour unquote(behaviour)
      @before_compile BlazeX.Core.Authoring
      @after_compile BlazeX.Core.Authoring
    end
  end

  defmacro __before_compile__(environment) do
    options = Module.get_attribute(environment.module, :blazex_authoring)
    %{required: required, optional: optional} = Contract.callbacks(options.role)
    functions = Module.definitions_in(environment.module, :def)
    expected = Enum.map(required ++ optional, &{&1, 1})
    if Enum.any?(required, &({&1, 1} not in functions)), do: fail!(:missing_callback)

    if Enum.any?(functions, &(&1 not in expected)) or
         Module.definitions_in(environment.module, :defmacro) != [],
       do: fail!(:unexpected_export)

    metadata = %{
      version: Contract.version(),
      role: options.role,
      visibility: :public_candidate,
      implementation: :private,
      callbacks: Enum.sort(functions),
      required: required,
      optional: optional,
      declarations: Map.new(@options -- [:role, :schema], &{&1, Map.get(options, &1, [])})
    }

    metadata =
      if Map.has_key?(options, :schema) do
        Map.merge(metadata, %{
          version: BlazeX.Component.Schema.version(),
          schema: validate_schema!(options.schema)
        })
      else
        metadata
      end

    quote do
      def __blazex_component__, do: unquote(Macro.escape(metadata))
    end
  end

  defp validate_schema!(schema) do
    if not Keyword.keyword?(schema) or Keyword.keys(schema) != [:props, :slots],
      do: fail!(:invalid_schema)

    case BlazeX.Component.Props.declare(schema[:props]) do
      {:ok, props} ->
        case BlazeX.Component.Slots.declare(schema[:slots]) do
          {:ok, slots} -> %{version: 1, props: props, slots: slots, declarations: schema}
          _ -> fail!(:invalid_schema)
        end

      _ ->
        fail!(:invalid_schema)
    end
  end

  def __after_compile__(_environment, binary) do
    {:ok, {_module, [{:imports, imports}]}} = :beam_lib.chunks(binary, [:imports])
    {:beam_file, _, _, _, _, functions} = :beam_disasm.file(binary)

    dynamic =
      Enum.any?(functions, fn {:function, _, _, _, instructions} ->
        Enum.any?(instructions, fn instruction ->
          is_tuple(instruction) and
            elem(instruction, 0) in [:call_fun, :call_fun2, :apply, :apply_last]
        end)
      end)

    if dynamic, do: fail!(:forbidden_dependency)
    if Enum.any?(imports, &(not allowed_import?(&1))), do: fail!(:forbidden_dependency)
  end

  defp allowed_import?({:erlang, name, _arity}) do
    name in [
      :get_module_info,
      :integer_to_binary,
      :map_get,
      :is_map,
      :is_atom,
      :is_binary,
      :is_integer,
      :is_list,
      :is_tuple,
      :is_float,
      :is_number,
      :length,
      :byte_size,
      :map_size,
      :tuple_size,
      :element,
      :hd,
      :tl,
      :setelement,
      :error,
      :raise,
      :+,
      :-,
      :*,
      :/,
      :div,
      :rem,
      :==,
      :"/=",
      :"=:=",
      :"=/=",
      :<,
      :>,
      :"=<",
      :>=,
      :++,
      :--,
      :not,
      :and,
      :or,
      :xor
    ]
  end

  defp allowed_import?({module, name, _arity}) do
    name not in [:apply, :binary_to_term, :to_atom, :to_existing_atom] and
      (module in [Enum, Map, List, Tuple, String, Integer, Float, Keyword] or
         module in [BlazeX.Component.Contract, BlazeX.Component.Input, BlazeX.Component.Result] or
         module in [
           BlazeX.UITree.Node,
           BlazeX.UITree.Document,
           BlazeX.UITree.Binding,
           BlazeX.UITree.Accessibility,
           BlazeX.UITree.Focus,
           BlazeX.UITree.Selection,
           BlazeX.UITree.Layout,
           BlazeX.UITree.TokenRef,
           BlazeX.UITree.Metric
         ])
  end

  defp fail!(code), do: raise(CompileError, description: "BH-05 authoring: #{code}")
end
