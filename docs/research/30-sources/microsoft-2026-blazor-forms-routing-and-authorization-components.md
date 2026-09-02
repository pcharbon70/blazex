---
title: "Blazor .NET 10 forms, routing, and authorization components"
kind: source
created: "2026-09-02"
authors:
  - "Microsoft"
published: null
citation_key: "microsoft-2026-blazor-forms-routing-auth"
container: "Microsoft Learn"
edition: ".NET 10"
isbn: null
doi: null
url: "https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.forms?view=aspnetcore-10.0"
accessed: "2026-09-02"
tags:
  - authentication
  - blazor
  - components
  - forms
  - routing
aliases:
  - "Blazor forms routing and auth catalog"
---

# Blazor .NET 10 forms, routing, and authorization components

## Reference

Microsoft. ASP.NET Core / Blazor .NET 10 API and framework documentation.
Accessed 2026-09-02. Principal references:

- [`Microsoft.AspNetCore.Components.Forms` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.forms?view=aspnetcore-10.0)
- [forms overview](https://learn.microsoft.com/en-us/aspnet/core/blazor/forms/?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.Routing` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.routing?view=aspnetcore-10.0)
- [routing](https://learn.microsoft.com/en-us/aspnet/core/blazor/fundamentals/routing?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.Authorization` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.authorization?view=aspnetcore-10.0)
- [authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?view=aspnetcore-10.0)
- [`Microsoft.AspNetCore.Components.WebAssembly.Authentication` API catalog](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.components.webassembly.authentication?view=aspnetcore-10.0)

## Research question or contribution

This source set enumerates Blazor's most substantial concrete built-in
component families and shows which semantics are renderer concerns, browser
concerns, server concerns, or .NET type-system conveniences.

## Findings

### Forms

- `EditForm` renders a form and cascades an `EditContext`. `EditContext`
  tracks the model, modified fields, validation messages, field CSS state,
  and validation events.
- `InputBase<TValue>` is the common integration point for typed controls.
  Concrete inputs in the .NET 10 catalog are `InputCheckbox`, `InputDate`,
  `InputFile`, `InputHidden`, `InputNumber`, `InputRadio`,
  `InputRadioGroup`, `InputSelect`, `InputText`, and `InputTextArea`.
- `Label<TValue>` and `DisplayName<TValue>` derive display labels from .NET
  metadata. `Editor<T>` is a typed editing abstraction.
- `DataAnnotationsValidator`, `ValidationMessage<TValue>`, and
  `ValidationSummary` connect validation state to rendered feedback.
- `AntiforgeryToken` emits a hidden token. `FormMappingScope` and
  `SupplyParameterFromForm` support static form post mapping and name scopes.
- `InputFile` exposes browser-selected files and streams. Client-reported
  metadata is explicitly untrusted.

### Routing and navigation

- `Router` maps the current browser location to route data by discovering
  components carrying route metadata. `RouteView` instantiates the selected
  page within its layouts.
- `NavLink` renders an anchor and manages its active class.
  `FocusOnNavigate` moves focus after page navigation for accessibility.
  `NavigationLock` can intercept internal and external navigation.
- `NavigationManager` is the imperative URI/history abstraction. Route and
  query parameters are supplied to component parameters through routing
  metadata and `SupplyParameterFromQuery`.

### Authentication and authorization

- `AuthorizeView` selects authorized, unauthorized, or authorizing content.
  Roles and policies are presentation inputs.
- `AuthorizeRouteView` combines `RouteView` and `AuthorizeView` behavior and
  supplies authentication state to descendants.
- `CascadingAuthenticationState` is the historical component wrapper; modern
  applications normally register cascading authentication-state services.
- `RemoteAuthenticatorView` and its generic core coordinate browser-side
  remote/OIDC authentication flows through JavaScript and route actions.
- Microsoft explicitly warns that `AuthorizeView` only changes rendered
  visibility. It does not secure an event handler, API, or destination route;
  protected operations still require authoritative authorization.

## Relevance

Phoenix has strong but differently shaped native facilities: `Phoenix.Component.form`,
`to_form`, changesets, router-owned LiveViews, live navigation, `on_mount`, and
server-side event authorization. BlazeX therefore needs a stable form-state
and input library for local execution, but it should adapt Phoenix routing and
security rather than recreate ASP.NET Core middleware or trust browser claims.

## Limits

The API catalog includes framework mechanics as well as components. It is not
a visual design-system inventory: Blazor does not provide framework buttons,
dialogs, tabs, charts, or a general styled control suite. Static server form
behavior and interactive form behavior are host-dependent. No OIDC provider,
file upload, or validation benchmark was executed in this pass.

## Derived work

- [Blazor framework semantics beneath BlazeX](../20-notes/blazor-framework-semantics-beneath-blazex.md)
- [BlazeX component semantics inquiry](../40-inquiries/which-foundational-component-semantics-does-blazex-need.md)
- [Component-semantics deep-dive journal](../50-journal/2026-09-02-blazor-component-semantics-deep-dive.md)
