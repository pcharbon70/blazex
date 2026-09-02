---
title: "Blazor .NET 10 component contracts, composition, styling, and interop"
kind: source
created: "2026-09-02"
authors:
  - "Microsoft"
published: null
citation_key: "microsoft-2026-blazor-component-contracts"
container: "Microsoft Learn"
edition: ".NET 10"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components?view=aspnetcore-10.0"
accessed: "2026-09-02"
tags:
  - blazor
  - components
  - css
  - dotnet
  - javascript-interop
aliases:
  - "Blazor built-in component contracts"
---

# Blazor .NET 10 component contracts, composition, styling, and interop

## Reference

Microsoft. ASP.NET Core / Blazor .NET 10 API and framework documentation.
Accessed 2026-09-02. Principal references:

- [`Microsoft.AspNetCore.Components` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components?view=aspnetcore-10.0)
- [Razor components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/?view=aspnetcore-10.0)
- [component lifecycle](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/lifecycle?view=aspnetcore-10.0)
- [dynamic components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/dynamiccomponent?view=aspnetcore-10.0)
- [templated components](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/templated-components?view=aspnetcore-10.0)
- [generic type support](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/generic-type-support?view=aspnetcore-10.0)
- [cascading values and parameters](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/cascading-values-and-parameters?view=aspnetcore-10.0)
- [event handling](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/event-handling?view=aspnetcore-10.0)
- [data binding](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/data-binding?view=aspnetcore-10.0)
- [element, component, and model relationships](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/element-component-model-relationships?view=aspnetcore-10.0)
- [CSS isolation](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/css-isolation?view=aspnetcore-10.0)
- [JavaScript location and collocation](https://learn.microsoft.com/en-us/aspnet/core/blazor/javascript-interoperability/location-of-javascript?view=aspnetcore-10.0)

## Research question or contribution

These pages define the reusable contracts beneath Blazor's concrete built-in
components: component identity, parameters, callbacks, child content,
templating, generic types, dynamic dispatch, ambient context, lifecycle,
binding, keys, references, styling, and browser interoperation.

## Method

The public namespace catalog was used to bound the API surface. The conceptual
documentation was then read by contract rather than by tutorial example. The
review distinguishes public component classes from Razor syntax, companion
types, build features, and project-template components.

## Findings

- `IComponent` is the minimal renderer contract and `ComponentBase` is the
  normal optional base class. Parameters arrive from the parent through a
  `ParameterView`; `[Parameter]` and `[EditorRequired]` describe author-facing
  inputs, with `EditorRequired` producing design/build guidance rather than a
  runtime non-null guarantee.
- `EventCallback` and `EventCallback<T>` provide child-to-parent event
  callbacks. DOM event delegates run only for interactive components and
  normally trigger rendering after the handler completes.
- `RenderFragment` and `RenderFragment<T>` represent ordinary and contextual
  child content. Templated components expose one or more such parameters.
- Generic component type parameters are a C# compile-time facility.
  `CascadingTypeParameter` can propagate generic type information by name.
- `DynamicComponent` renders a component selected by runtime `Type`, accepts a
  string/object parameter dictionary, and exposes the resulting instance.
- `CascadingValue<T>` supplies ambient values to descendants selected by type
  and optionally name. Subscriptions can rerender consumers when values
  change, but cascades do not automatically cross render-mode boundaries.
- `ComponentBase` lifecycle phases cover initialization, parameter receipt,
  rendering, after-render work, and disposal. `ShouldRender` can suppress a
  non-initial render. After-render callbacks require an interactive DOM and do
  not execute during static/prerender output.
- `@key` controls element/component preservation within a sibling scope.
  `@ref` can expose a DOM element handle or component instance, although the
  documentation recommends declarative parameters instead of mutating child
  component state through a reference.
- Two-way component binding is conventionally a value parameter plus a
  `{Value}Changed` callback. `@bind:get` and `@bind:set` make the flow explicit
  and allow transformation before a value reaches the DOM.
- CSS isolation rewrites selectors at build time and places generated scope
  attributes on rendered elements. Razor class library styles are bundled
  into the consuming application.
- A component may collocate a `.razor.js` module. Publication moves that file
  into static assets; application code imports it through `IJSRuntime` and
  should dispose retained JavaScript object references.

## Relevance

This contract inventory is design input, not a target API. BlazeX can address
the same classes of problem through native Elixir mechanisms: HEEx attributes
for parameters, slots for render fragments, messages/events for callbacks,
manifest-bounded dynamic dispatch, explicit context where useful, and
capability-scoped browser effects instead of arbitrary object references.

## Limits

Microsoft Learn API pages can include preview notices and multi-version
content. Only APIs presented under the explicit ASP.NET Core 10 view are used
as the baseline; .NET 11 preview examples are excluded. The documentation is
normative product guidance, not an independent performance or ergonomics
comparison. No Blazor application was compiled in this research pass.

## Derived work

- [Blazor framework semantics beneath BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [BlazeX component semantics inquiry](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Component-semantics deep-dive journal](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md)
