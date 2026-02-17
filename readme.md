# Truth Table Generator

An interactive Bash script for building and evaluating logical expressions as truth tables. Supports AND, OR, and NOT with proper De Morgan's Law handling across chained expressions of up to 10 variables.

## Usage

```bash
chmod +x truth_table.sh
./truth_table.sh
```

## How It Works

The script starts with a single variable `p`. Each time you add an AND or OR operator, the next variable in the sequence (`q`, `r`, `s`, …) is added to the chain. Press Enter at any time to evaluate and display the full truth table.

```
  +------------------------------------------+
  |   TRUTH TABLE GENERATOR  -- Upgraded     |
  |   Build: p && q,  !p || q,  p && q || r  |
  +------------------------------------------+

  Start with 'p'. Each AND/OR adds the next variable.
  Use NOT (option 3) before adding an operand to negate it.
  Or toggle NOT on any existing operand with option 4.

------------------------------------------
 Expression: p
 Operands:   1  / Variables: p
------------------------------------------
 1  Add AND (&&)
 2  Add OR  (||)
 3  Queue NOT for next operand
 4  Toggle NOT on an existing operand
 5  Preview table
 r  Reset
 q  Quit
 [Enter]  Evaluate & show final truth table
------------------------------------------
```

## Menu Options

| Key | Action |
|-----|--------|
| `1` | Add AND (`&&`) — appends the next variable with AND |
| `2` | Add OR (`\|\|`) — appends the next variable with OR |
| `3` | Queue NOT — the *next* operand you add will be negated |
| `4` | Toggle NOT on an already-added operand |
| `5` | Preview the truth table without committing |
| `r` | Reset the chain and start over |
| `q` | Quit |
| `↵` | Evaluate and display the final truth table |

## Examples

### p AND q
Press `1`, then `↵`:
```
============ Truth Table ============
  p   q  | Result
-------------------
  0   0  |  0
  0   1  |  0
  1   0  |  0
  1   1  |  1
  Expression: p && q
```

### p AND !q
Press `3` (queue NOT), then `1` (AND), then `↵`:
```
============ Truth Table ============
  p  !q  | Result
-------------------
  0   1  |  0
  0   0  |  0
  1   1  |  1
  1   0  |  0
  Expression: p && !q
```

### !p OR !q — De Morgan's of (p AND q)
Press `2` (OR), then `4` (toggle NOT on p), then `↵`:
```
============ Truth Table ============
 !p  !q  | Result
-------------------
  1   1  |  1
  1   0  |  1
  0   1  |  1
  0   0  |  0
  Expression: !p || !q
```

### Three-variable chain: p AND q OR r
Press `1`, then `2`, then `↵`:
```
============ Truth Table ============
  p   q   r  | Result
-----------------------
  0   0   0  |  0
  0   0   1  |  1
  0   1   0  |  0
  0   1   1  |  1
  1   0   0  |  0
  1   0   1  |  1
  1   1   0  |  1
  1   1   1  |  1
  Expression: p && q || r
```

## NOT and De Morgan's Law

Negation is handled per-operand rather than by rewriting the expression. This means:

- Press `3` **before** adding an AND/OR to negate the incoming variable
- Press `4` **after** to flip the negation on any variable already in the chain

To express De Morgan's Law manually — `!(p AND q)` ≡ `!p OR !q` — add an OR, then use option `4` to negate both `p` and `q`.

## Notes

- Expressions are evaluated left-to-right with standard Bash arithmetic precedence (`&&` binds tighter than `||`)
- Up to 10 variables supported: `p q r s t u v w x y`
- Requires Bash 4.0+ (for `readarray` / `declare -a`)

## Requirements

```
bash >= 4.0
grep (with -P support, standard on Linux)
```
