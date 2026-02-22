# [plex-autoskip] — [Short title]

---

## TL;DR

| | |
|---|---|
| **What** | One-line summary of the change. |
| **Why safe** | One-line: why this is safe. |
| **Proof** | One-line: how you verified (e.g. `helm template` OK). |

---

## Summary

| Icon | Change |
|------|--------|
| | **Change 1** — Short description. |

---

## Setup requirements (if any)

*(Omit if none.)*

---

## Render & validation

> **Command used:**  
> `helm template plex-auto-skip . -f values.yaml -n plex`

| Check | Result |
|-------|--------|
| `helm template ...` | OK / failed |

---

## Supporting evidence

<details>
<summary>Relevant snippet</summary>

```yaml
# Rendered YAML excerpt.
```

</details>

---

## Why this change is safe & correct

| Change | What we did | Why it's safe | Proof |
|--------|--------------|---------------|-------|
| | | | |

---

## Next steps

| Step | Action |
|------|--------|
| 1 | Merge; *(what happens next)*. |

---

**Checklist**

- [ ] Title starts with `[plex-autoskip]`.
- [ ] Chart version bumped in `Chart.yaml` if applicable (semver).
- [ ] `helm dependency update` and `helm template` succeed.
