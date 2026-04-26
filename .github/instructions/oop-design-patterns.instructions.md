---
description: 'SOLID principles and core OOP design philosophy for clean, maintainable code.'
applyTo: '**/*.py, **/*.java, **/*.ts, **/*.js, **/*.cs'
---

# OOP Design Principles

## Core Philosophy

- **Program to an Interface, not an Implementation.** Favor abstract classes or interfaces over concrete implementations. Use dependency injection to provide concrete instances.
- **Favor Composition over Inheritance.** Combine behaviors dynamically at runtime. Avoid deep inheritance trees. Use delegation to reuse behavior without breaking encapsulation.
- **Encapsulate What Varies.** Separate the aspects that change from what stays the same. Use Strategy, State, or Bridge to isolate variations.
- **Loose Coupling.** Minimize direct dependencies between classes. Use abstractions, events, or mediators to keep components decoupled.

## SOLID Principles

- **Single Responsibility:** Each class has only one reason to change. If a class does too much, split it.
- **Open/Closed:** Open for extension, closed for modification. Use interfaces to allow new behavior without changing existing code.
- **Liskov Substitution:** Subclasses must be substitutable for their base classes without breaking correctness.
- **Interface Segregation:** Prefer many specific interfaces over one general-purpose interface. Clients should not depend on methods they don't use.
- **Dependency Inversion:** Depend on abstractions, not concretions. High-level modules and low-level modules both depend on abstractions.

## Code Generation Rules

- **Interface First:** Generate the interface or abstract base class before concrete implementations.
- **Fields are `private` by default.** Provide getters/setters only when necessary. Favor immutable objects.
- **No God Classes.** Break large classes into smaller, focused classes with clear responsibilities.
- **Apply patterns judiciously.** Use GoF patterns (Factory, Strategy, Observer, Decorator, etc.) when they solve a real problem — not for the sake of using a pattern.
- **Name with intent.** Use pattern names in class names when it aids understanding (e.g., `TaxCalculationStrategy`, `WidgetFactory`), but keep names domain-natural when appropriate.
- **Favor functions over classes** when the problem can be solved with a simple function. Use classes when they provide clear organizational benefits.
