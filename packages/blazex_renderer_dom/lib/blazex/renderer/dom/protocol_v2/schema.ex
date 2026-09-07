defmodule BlazeX.Renderer.DOM.ProtocolV2.Schema do
  @moduledoc false
  @schemas %{
    "transaction" => %{
      "type" => "object",
      "properties" => %{
        "record" => %{"enum" => ["transaction"]},
        "protocol" => %{"enum" => ["blazex.dom-transaction/2"]},
        "schema" => %{"enum" => ["2.0.0"]},
        "owner" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^root-[a-z0-9_-]{1,59}$"},
        "generation" => %{"type" => "integer", "minimum" => 1, "maximum" => 9_007_199_254_740_991},
        "root" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"},
        "base_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "target_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "transaction_id" => %{
          "type" => "string",
          "maxBytes" => 27,
          "pattern" => "^tx-[0-9a-f]{24}$"
        },
        "digest" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^[0-9a-f]{64}$"},
        "kind" => %{"enum" => ["initial", "patch", "replace", "dispose"]},
        "features" => %{
          "type" => "array",
          "items" => %{"enum" => ["atomic", "ordered"]},
          "minItems" => 2,
          "maxItems" => 2
        },
        "operations" => %{
          "type" => "array",
          "items" => %{
            "oneOf" => [
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["create"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "tag" => %{"enum" => ["span", "div", "button", "input", "ul", "li", "section"]},
                  "text" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 4096}]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "tag", "text"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["insert"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "parent" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  },
                  "anchor" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  },
                  "old_parent" => %{"type" => "null"}
                },
                "required" => [
                  "op_id",
                  "depends",
                  "type",
                  "target",
                  "parent",
                  "anchor",
                  "old_parent"
                ],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["move"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "parent" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  },
                  "anchor" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  },
                  "old_parent" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  }
                },
                "required" => [
                  "op_id",
                  "depends",
                  "type",
                  "target",
                  "parent",
                  "anchor",
                  "old_parent"
                ],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["remove"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "old_parent" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "old_parent"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["replace"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "value" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "parent" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  },
                  "anchor" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                    ]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "value", "parent", "anchor"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["text"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "old" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 4096}]
                  },
                  "new" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 4096}]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "old", "new"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["attribute"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "name" => %{
                    "enum" => [
                      "role",
                      "aria-label",
                      "aria-description",
                      "aria-disabled",
                      "aria-expanded",
                      "aria-selected",
                      "aria-checked",
                      "aria-invalid",
                      "aria-required",
                      "aria-readonly",
                      "aria-busy",
                      "aria-live",
                      "type",
                      "data-bx-kind",
                      "aria-labelledby",
                      "aria-describedby",
                      "aria-controls",
                      "aria-owns",
                      "aria-errormessage",
                      "data-bx-layout-mode",
                      "data-bx-layout-direction",
                      "data-bx-layout-align",
                      "data-bx-layout-gap",
                      "data-bx-layout-padding",
                      "data-bx-layout-width",
                      "data-bx-layout-height",
                      "data-bx-layout-min-width",
                      "data-bx-layout-min-height",
                      "data-bx-layout-max-width",
                      "data-bx-layout-max-height",
                      "data-bx-layout-grow",
                      "data-bx-layout-overflow",
                      "data-bx-layout-virtualization"
                    ]
                  },
                  "old" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 2048}]
                  },
                  "new" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 2048}]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "name", "old", "new"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["property"]},
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "name" => %{"enum" => ["value", "checked", "disabled", "readOnly", "selected"]},
                  "old" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "boolean"},
                      %{"type" => "string", "maxBytes" => 2048}
                    ]
                  },
                  "new" => %{
                    "oneOf" => [
                      %{"type" => "null"},
                      %{"type" => "boolean"},
                      %{"type" => "string", "maxBytes" => 2048}
                    ]
                  }
                },
                "required" => ["op_id", "depends", "type", "target", "name", "old", "new"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "type" => %{"enum" => ["effect_barrier"]},
                  "barrier" => %{"enum" => ["post-commit"]},
                  "resources" => %{
                    "type" => "array",
                    "items" => %{
                      "type" => "string",
                      "maxBytes" => 64,
                      "pattern" => "^resource-[a-z0-9_-]+$"
                    },
                    "maxItems" => 256
                  }
                },
                "required" => ["op_id", "depends", "type", "barrier", "resources"],
                "additionalProperties" => false
              },
              %{
                "type" => "object",
                "properties" => %{
                  "type" => %{"enum" => ["intent"]},
                  "op_id" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                  "depends" => %{
                    "type" => "array",
                    "items" => %{"type" => "integer", "minimum" => 0, "maximum" => 511},
                    "maxItems" => 512
                  },
                  "target" => %{
                    "type" => "string",
                    "maxBytes" => 27,
                    "pattern" => "^bx-[0-9a-f]{24}$"
                  },
                  "name" => %{"enum" => ["focus", "selection", "listeners"]},
                  "old" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 4096}]
                  },
                  "new" => %{
                    "oneOf" => [%{"type" => "null"}, %{"type" => "string", "maxBytes" => 4096}]
                  }
                },
                "additionalProperties" => false,
                "required" => ["type", "op_id", "depends", "target", "name", "old", "new"]
              }
            ]
          },
          "maxItems" => 512
        }
      },
      "required" => [
        "record",
        "protocol",
        "schema",
        "owner",
        "generation",
        "root",
        "base_revision",
        "target_revision",
        "transaction_id",
        "digest",
        "kind",
        "features",
        "operations"
      ],
      "additionalProperties" => false
    },
    "ack" => %{
      "type" => "object",
      "properties" => %{
        "record" => %{"enum" => ["ack"]},
        "protocol" => %{"enum" => ["blazex.dom-transaction/2"]},
        "schema" => %{"enum" => ["2.0.0"]},
        "owner" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^root-[a-z0-9_-]{1,59}$"},
        "generation" => %{"type" => "integer", "minimum" => 1, "maximum" => 9_007_199_254_740_991},
        "root" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"},
        "base_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "target_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "transaction_id" => %{
          "type" => "string",
          "maxBytes" => 27,
          "pattern" => "^tx-[0-9a-f]{24}$"
        },
        "digest" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^[0-9a-f]{64}$"},
        "state" => %{
          "enum" => [
            "preflight",
            "accepted",
            "committed",
            "rejected",
            "rolled-back",
            "fallback",
            "disposed"
          ]
        },
        "diagnostic" => %{
          "oneOf" => [
            %{"type" => "null"},
            %{
              "enum" => [
                "malformed",
                "incompatible",
                "stale",
                "duplicate",
                "missing-target",
                "ownership",
                "limit",
                "apply",
                "rollback",
                "disposed-root"
              ]
            }
          ]
        }
      },
      "required" => [
        "record",
        "protocol",
        "schema",
        "owner",
        "generation",
        "root",
        "base_revision",
        "target_revision",
        "transaction_id",
        "digest",
        "state",
        "diagnostic"
      ],
      "additionalProperties" => false
    },
    "diagnostic" => %{
      "type" => "object",
      "properties" => %{
        "record" => %{"enum" => ["diagnostic"]},
        "protocol" => %{"enum" => ["blazex.dom-transaction/2"]},
        "schema" => %{"enum" => ["2.0.0"]},
        "owner" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^root-[a-z0-9_-]{1,59}$"},
        "generation" => %{"type" => "integer", "minimum" => 1, "maximum" => 9_007_199_254_740_991},
        "root" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"},
        "base_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "target_revision" => %{
          "type" => "integer",
          "minimum" => 0,
          "maximum" => 9_007_199_254_740_991
        },
        "transaction_id" => %{
          "type" => "string",
          "maxBytes" => 27,
          "pattern" => "^tx-[0-9a-f]{24}$"
        },
        "digest" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^[0-9a-f]{64}$"},
        "code" => %{
          "enum" => [
            "malformed",
            "incompatible",
            "stale",
            "duplicate",
            "missing-target",
            "ownership",
            "limit",
            "apply",
            "rollback",
            "disposed-root"
          ]
        },
        "operation_id" => %{
          "oneOf" => [
            %{"type" => "null"},
            %{"type" => "integer", "minimum" => 0, "maximum" => 511}
          ]
        }
      },
      "required" => [
        "record",
        "protocol",
        "schema",
        "owner",
        "generation",
        "root",
        "base_revision",
        "target_revision",
        "transaction_id",
        "digest",
        "code",
        "operation_id"
      ],
      "additionalProperties" => false
    },
    "context" => %{
      "type" => "object",
      "properties" => %{
        "owner" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^root-[a-z0-9_-]{1,59}$"},
        "generation" => %{"type" => "integer", "minimum" => 1, "maximum" => 9_007_199_254_740_991},
        "revision" => %{"type" => "integer", "minimum" => 0, "maximum" => 9_007_199_254_740_991},
        "root" => %{
          "oneOf" => [
            %{"type" => "null"},
            %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
          ]
        },
        "disposed" => %{"type" => "boolean"},
        "nodes" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "id" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"},
              "parent" => %{
                "oneOf" => [
                  %{"type" => "null"},
                  %{"type" => "string", "maxBytes" => 27, "pattern" => "^bx-[0-9a-f]{24}$"}
                ]
              }
            },
            "required" => ["id", "parent"],
            "additionalProperties" => false
          },
          "maxItems" => 128
        },
        "listeners" => %{
          "type" => "array",
          "items" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^bl-[0-9a-f]{24}$"},
          "maxItems" => 256
        },
        "seen" => %{
          "type" => "array",
          "items" => %{"type" => "string", "maxBytes" => 27, "pattern" => "^tx-[0-9a-f]{24}$"},
          "maxItems" => 64
        },
        "transaction" => %{
          "oneOf" => [
            %{"type" => "null"},
            %{
              "type" => "object",
              "properties" => %{
                "protocol" => %{"type" => "string", "maxBytes" => 128},
                "schema" => %{"type" => "string", "maxBytes" => 32},
                "owner" => %{
                  "type" => "string",
                  "maxBytes" => 64,
                  "pattern" => "^root-[a-z0-9_-]{1,59}$"
                },
                "generation" => %{
                  "type" => "integer",
                  "minimum" => 1,
                  "maximum" => 9_007_199_254_740_991
                },
                "root" => %{
                  "type" => "string",
                  "maxBytes" => 27,
                  "pattern" => "^bx-[0-9a-f]{24}$"
                },
                "base_revision" => %{
                  "type" => "integer",
                  "minimum" => 0,
                  "maximum" => 9_007_199_254_740_991
                },
                "target_revision" => %{
                  "type" => "integer",
                  "minimum" => 0,
                  "maximum" => 9_007_199_254_740_991
                },
                "transaction_id" => %{
                  "type" => "string",
                  "maxBytes" => 27,
                  "pattern" => "^tx-[0-9a-f]{24}$"
                },
                "digest" => %{"type" => "string", "maxBytes" => 64, "pattern" => "^[0-9a-f]{64}$"},
                "kind" => %{"enum" => ["initial", "patch", "replace", "dispose"]},
                "operation_count" => %{"type" => "integer", "minimum" => 0, "maximum" => 512}
              },
              "additionalProperties" => false,
              "required" => [
                "protocol",
                "schema",
                "owner",
                "generation",
                "root",
                "base_revision",
                "target_revision",
                "transaction_id",
                "digest",
                "kind",
                "operation_count"
              ]
            }
          ]
        }
      },
      "required" => [
        "owner",
        "generation",
        "revision",
        "root",
        "disposed",
        "nodes",
        "listeners",
        "seen",
        "transaction"
      ],
      "additionalProperties" => false
    }
  }
  def schemas, do: @schemas
  defdelegate valid?(value, schema), to: BlazeX.Renderer.DOM.Protocol.Schema
end
