# Extract Method — Java Examples

Apply Extract Method to improve readability, testability, cohesion, and reusability without changing behavior.

## When to Trigger

Identify methods exceeding any of these thresholds:

- **LOC** (Lines of Code) > 15
- **NOM** (Number of Statements) > 10
- **CC** (Cyclomatic Complexity) > 10

For each qualifying method, find code blocks with a **single named purpose** and extract them. Output complete, compilable Java 8 code.

## Rules

- Extract at least one new method with a descriptive name
- Do not remove any functionality from the original method
- Include a one-line comment above each new method describing its purpose
- New method visibility: `private` unless used externally; `protected` only if subclasses extend it

---

## Example 1 — Extract a guard / null-safe wrapper

### Before

```java
public FactLineBuilder setC_BPartner_ID_IfValid(final int bpartnerId) {
    assertNotBuild();
    if (bpartnerId > 0) {
        setC_BPartner_ID(bpartnerId);
    }
    return this;
}
```

### After

```java
// Sets the bpartner id if non-null; otherwise leaves the builder unchanged.
public FactLineBuilder bpartnerIdIfNotNull(final BPartnerId bpartnerId) {
    if (bpartnerId != null) {
        return bpartnerId(bpartnerId);
    } else {
        return this;
    }
}

public FactLineBuilder setC_BPartner_ID_IfValid(final int bpartnerRepoId) {
    return bpartnerIdIfNotNull(BPartnerId.ofRepoIdOrNull(bpartnerRepoId));
}
```

**What changed**: the validity check moved into a typed wrapper (`bpartnerIdIfNotNull`) that uses the domain type `BPartnerId` instead of a raw `int`. The original method becomes a one-line adapter from the legacy `int` API.

---

## Example 2 — Extract a factory hook for subclassing

### Before

```java
public DefaultExpander add(RelationshipType type, Direction direction) {
    Direction existingDirection = directions.get(type.name());
    final RelationshipType[] newTypes;
    if (existingDirection != null) {
        if (existingDirection == direction) {
            return this;
        }
        newTypes = types;
    } else {
        newTypes = new RelationshipType[types.length + 1];
        System.arraycopy(types, 0, newTypes, 0, types.length);
        newTypes[types.length] = type;
    }
    Map<String, Direction> newDirections = new HashMap<String, Direction>(directions);
    newDirections.put(type.name(), direction);
    return new DefaultExpander(newTypes, newDirections);
}
```

### After

```java
public DefaultExpander add(RelationshipType type, Direction direction) {
    Direction existingDirection = directions.get(type.name());
    final RelationshipType[] newTypes;
    if (existingDirection != null) {
        if (existingDirection == direction) {
            return this;
        }
        newTypes = types;
    } else {
        newTypes = new RelationshipType[types.length + 1];
        System.arraycopy(types, 0, newTypes, 0, types.length);
        newTypes[types.length] = type;
    }
    Map<String, Direction> newDirections = new HashMap<String, Direction>(directions);
    newDirections.put(type.name(), direction);
    return (DefaultExpander) newExpander(newTypes, newDirections);
}

// Factory hook for subclasses to return their own expander type.
protected RelationshipExpander newExpander(RelationshipType[] types,
        Map<String, Direction> directions) {
    return new DefaultExpander(types, directions);
}
```

**What changed**: the constructor call became a `protected` factory method so subclasses can override the expander type without copy-pasting the whole `add` method. Behavior in `DefaultExpander` itself is unchanged.
