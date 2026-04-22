# Truth Table Generator Script

An interactive Bash script for building and evaluating logical expressions as truth tables. Supports AND, OR, XOR, NOT, parenthesis grouping, and file export. Variables are auto-named `p, q, r, …` as you build.

## Requirements

```
bash >= 4.0
```

> **macOS note:** This script uses `grep -oE` rather than `grep -oP`, so it works with the BSD grep that ships with macOS — no Homebrew required.

## Usage

```bash
chmod +x truth_table.sh
./truth_table.sh
```

## Menu Reference

| Key | Action |
|-----|--------|
| `1` | Add AND (`&&`) — appends the next variable |
| `2` | Add OR (`\|\|`) — appends the next variable |
| `3` | Add XOR (`^`) — appends the next variable |
| `n` | Queue NOT — the next variable you add will be negated |
| `(` | Queue open parenthesis — placed before the next operator |
| `)` | Close parenthesis |
| `t` | Toggle NOT on an already-added variable |
| `u` | Undo the last token |
| `5` | Preview the truth table without committing |
| `e` | Export last evaluated table to `.txt` or `.csv` |
| `r` | Reset the expression and start over |
| `q` | Quit |
| `↵` | Evaluate and display the final truth table |

## Examples

### p AND q
Press `1`, then `↵`:
```
Expression: p && q
  p   q  | Result
-------------------
  0   0  |  0
  0   1  |  0
  1   0  |  0
  1   1  |  1
```

### p XOR q
Press `3`, then `↵`:
```
Expression: p ^ q
  p   q  | Result
-------------------
  0   0  |  0
  0   1  |  1
  1   0  |  1
  1   1  |  0
```
XOR is true when exactly one operand is true.

### p AND !q
Press `n` (queue NOT), then `1` (AND), then `↵`:
```
Expression: p && !q
  p  !q  | Result
-------------------
  0   1  |  0
  0   0  |  0
  1   1  |  1
  1   0  |  0
```

### !p OR !q — De Morgan's of (p AND q)
Press `2` (OR), then `t` to toggle NOT on `p`, then `↵`:
```
Expression: !p || !q
 !p  !q  | Result
-------------------
  1   1  |  1
  1   0  |  1
  0   1  |  1
  0   0  |  0
```
Equivalent to `!(p && q)` — false only when both are true.

### Parenthesis grouping: why it matters

`(p || q) && r` and `p && (q || r)` look similar but give different results:

`(p || q) && r`:
```
Expression: (p || q) && r
  p   q   r  | Result
-----------------------
  0   0   0  |  0
  0   0   1  |  0
  0   1   0  |  0
  0   1   1  |  1
  1   0   0  |  0
  1   0   1  |  1
  1   1   0  |  0
  1   1   1  |  1
```

`p && (q || r)`:
```
Expression: p && (q || r)
  p   q   r  | Result
-----------------------
  0   0   0  |  0
  0   0   1  |  0
  0   1   0  |  0   ← differs
  0   1   1  |  0   ← differs
  1   0   0  |  0
  1   0   1  |  1
  1   1   0  |  1
  1   1   1  |  1
```

Rows where `p=0` and `q=1` differ between the two — grouping changes the logic.

## NOT and De Morgan's Law

Negation is stored as a per-variable flag, not by rewriting the expression string. Two ways to apply it:

- Press `n` **before** adding an operator to negate the incoming variable.
- Press `t` **after** to flip negation on any variable already in the chain.

De Morgan's Law states that `!(p AND q)` is equivalent to `!p OR !q`. You can verify this by building both expressions and comparing their result columns — they will be identical.

## Export

After evaluating a table, press `e` to save it:

- **`.txt`** — human-readable table with aligned columns
- **`.csv`** — spreadsheet-compatible with expression metadata in the header

The filename is derived from the expression, e.g. `truth_pandq.txt`.

## Known Limitations

- Expressions are evaluated using Bash's built-in arithmetic, so operator precedence follows Bash rules: `^` (XOR) binds tightest, then `&&`, then `||`. Use parentheses to override.
- Maximum 10 variables (`p` through `y`).
- A `(` is always placed before the next operator you add — use it to start a grouped sub-expression before adding the operator that opens the group.
