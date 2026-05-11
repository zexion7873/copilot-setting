# Remove Parameter — Java Examples

Apply Remove Parameter to eliminate unused or redundant arguments — values derivable from class fields, constants, or other accessible state.

## When to Trigger

Identify parameters that are:

- **Unused** — never read inside the method body
- **Redundant** — could be obtained from `this.field`, a constant, or another parameter
- **Always the same value** — every caller passes the same literal

For each, remove from the method signature **and every call site** in one atomic change. Output complete, compilable Java 8 code.

## Rules

- Do not remove any functionality from the original method
- Update **all** call sites — do not leave stale callers compiling but passing dead args
- Include a one-line comment above each modified method noting which parameter was removed and why
- If the parameter is part of a public API, deprecate the old signature first; remove only after callers migrate

---

## Example 1 — Remove a parameter derivable from existing state

### Before

```java
public Backend selectBackendForGroupCommit(long tableId, ConnectContext context, boolean isCloud)
        throws LoadException, DdlException {
    if (!Env.getCurrentEnv().isMaster()) {
        try {
            long backendId = new MasterOpExecutor(context)
                    .getGroupCommitLoadBeId(tableId, context.getCloudCluster(), isCloud);
            return Env.getCurrentSystemInfo().getBackend(backendId);
        } catch (Exception e) {
            throw new LoadException(e.getMessage());
        }
    } else {
        return Env.getCurrentSystemInfo()
                .getBackend(selectBackendForGroupCommitInternal(tableId, context.getCloudCluster(), isCloud));
    }
}
```

### After

```java
// Removed `isCloud`: derivable from `context.getCloudCluster()` non-null check downstream.
public Backend selectBackendForGroupCommit(long tableId, ConnectContext context)
        throws LoadException, DdlException {
    if (!Env.getCurrentEnv().isMaster()) {
        try {
            long backendId = new MasterOpExecutor(context)
                    .getGroupCommitLoadBeId(tableId, context.getCloudCluster());
            return Env.getCurrentSystemInfo().getBackend(backendId);
        } catch (Exception e) {
            throw new LoadException(e.getMessage());
        }
    } else {
        return Env.getCurrentSystemInfo()
                .getBackend(selectBackendForGroupCommitInternal(tableId, context.getCloudCluster()));
    }
}
```

**What changed**: `isCloud` was redundant — the cloud cluster identity is already encoded in `context`. Cascading removal from `getGroupCommitLoadBeId` and `selectBackendForGroupCommitInternal` keeps the API consistent.

---

## Example 2 — Remove unused constructor parameters

### Before

```java
NodeImpl(long id, long firstRel, long firstProp) {
    this(id, false);
}
```

### After

```java
// Removed `firstRel` and `firstProp`: both unused; existed for legacy ctor symmetry.
NodeImpl(long id) {
    this(id, false);
}
```

**What changed**: the two parameters were never read by the constructor body. Removing them simplifies callers and prevents future readers from wondering what they were for.
