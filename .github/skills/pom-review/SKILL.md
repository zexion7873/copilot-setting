---
name: pom-review
description: 'Use when user needs Maven pom.xml reviewed for dependency hygiene, known-CVE versions, version conflicts, scope correctness, or SNAPSHOT discipline. Triggers on: review pom, pom review, Maven dependency audit, dependency review, CVE check, 看 pom, 審查依賴, Maven 套件, 依賴版本. Produces severity-classified pom findings with version remediation guidance. Do NOT use for application code review (prefer code-review), runtime security exploits (prefer security-audit), or build performance tuning (prefer performance).'
---

# POM Review — Workflow

Maven `pom.xml` review. Companion rules: `instructions/xml-config.instructions.md`.

**Canonical rules — open the instruction files** (agent mode can read them directly):

- `instructions/xml-config.instructions.md` — Spring XML, hbm.xml, Maven POM conventions
- `instructions/no-heredoc.instructions.md` — edit files with tools, not terminal redirection

Focus: dependency hygiene (versions, scopes, conflicts), known-CVE versions, build plugin pinning, SNAPSHOT discipline, and project metadata consistency.

## Phase 1 — Inventory Dependencies

- List all `<dependency>` entries with groupId / artifactId / version / scope.
- Note whether versions are direct or inherited from `<dependencyManagement>` or parent POM.
- Flag any `<version>` referencing `${...}` properties — confirm property is defined in parent or local `<properties>`.

## Phase 2 — Version Hygiene

- [ ] No `SNAPSHOT` dependencies in release builds (allowed only inside actively-developed sibling module)
- [ ] No `LATEST` / `RELEASE` version markers (build reproducibility)
- [ ] All versions managed via `<dependencyManagement>` in the parent POM (no per-module duplicates)
- [ ] No two different versions of the same `groupId:artifactId` across the dependency tree (run `mvn dependency:tree` if uncertain)

## Phase 3 — Security & CVE Check

- [ ] Compare key dependency versions against published CVEs (Jackson, Logback / Log4j, Spring, Hibernate, Apache Commons)
- [ ] Flag any dependency older than the last patched-CVE version
- [ ] Verify `<dependencyManagement>` does not pin a vulnerable version
- [ ] Consult current advisory data — use `context7` or `websearch` for the latest CVE list per artifact

## Phase 4 — Scope & Plugin Discipline

- [ ] Test-only libraries declared with `<scope>test</scope>` (JUnit, Mockito, AssertJ)
- [ ] Servlet API declared `<scope>provided</scope>` for WAR builds
- [ ] All `<plugin>` versions explicitly pinned (no implicit Super POM defaults)
- [ ] `maven-compiler-plugin` `<source>` / `<target>` set to `1.8` for Java 8 projects

## Phase 5 — Report

Classify each finding by severity, then format using the Output Template below.

## Output Template

Per finding:

```
[SEVERITY] <title>
Coordinate: <groupId:artifactId:version>
Location: pom.xml:<line>
Issue: <what's wrong>
Fix: <specific remediation, e.g., "bump to 2.16.1; CVE-2023-35116 affects <2.15.4">
```

| Severity | Criteria |
|---|---|
| 🔴 CRITICAL | Known RCE / CVE with public exploit; `SNAPSHOT` in release pipeline |
| 🟠 MAJOR | Known CVE without public exploit; version conflict causing runtime failure |
| 🟡 MINOR | Unpinned plugin version; missing scope; duplicate declaration |
| ⚪ NIT | Property naming; ordering; missing comment |

Summary: `Dependencies reviewed: N | Findings: N critical, N major, N minor, N nit | Top issue: <most impactful>`

## Anti-Patterns

- `<version>LATEST</version>` / `<version>RELEASE</version>` — non-reproducible builds; pin an explicit version
- Same `groupId:artifactId` declared at two different versions across modules — let `<dependencyManagement>` decide one version
- Test scope omitted on JUnit / Mockito — bloats runtime classpath and may shadow real deps
- `maven-compiler-plugin` unpinned — Super POM upgrades can silently change behavior
- `SNAPSHOT` on a third-party dependency in a release build — non-reproducible and unsupported

## Handoffs

- → `@implementer` — to bump versions / fix scope issues
- → `security-audit` skill — if a CVE finding needs runtime exploit verification
- ← `@reviewer` — pom review mode activated
