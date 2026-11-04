# Resource and evaluation safety

Compiled schemas perform no I/O during validation. All external resources are
loaded eagerly through the `:resources` map or the caller-provided `:resolver`
during compilation. These options may be passed directly or inherited from
the `:ex_json_schema` application defaults. Each normalized retrieval URI is
loaded at most once, so ordinary reference cycles terminate.

The resolver is trusted application code and remains responsible for:

- allowing only intended URI schemes, hosts, and paths;
- applying connection and response timeouts;
- limiting response bytes and decoded JSON depth;
- limiting the number of distinct resources it is willing to serve; and
- avoiding credentials or network access that schema authors should not have.

The compiler does not impose a universal resource-count or byte quota. A
resolver that generates an unbounded chain of distinct resource identifiers
can therefore consume unbounded work. Applications accepting untrusted schemas
must enforce a quota in the resolver or preload a bounded resource set.

Evaluation guards non-progressing static and dynamic reference cycles by
tracking the target schema location, instance location, and dynamic scope.
Recursive schemas still follow genuinely deeper instance locations, as
required by JSON Schema. Applications accepting untrusted payloads should
bound decoded payload size and nesting depth before validation. Detailed and
verbose output can be substantially larger than the payload; use flag or basic
output when diagnostic trees are not needed.

The adversarial regression tests cover cyclic loading, a 100-resource acyclic
chain, non-progressing static and dynamic reference loops, and a 200-level
progressing recursive instance.
