#!/bin/bash
# ============================================================
#  Truth Table Generator — v2
#  Supports: AND(&&), OR(||), XOR(^), NOT(!), parentheses
#  Variables auto-named: p, q, r, s, t, …  (up to 10)
#  Export: save truth table as .txt or .csv
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
MAGENTA='\033[0;35m'

var_names=(p q r s t u v w x y)

# ── macOS / BSD grep compatibility ────────────────────────────
# grep -P (Perl regex) is GNU only; macOS ships BSD grep.
# We use grep -oE '[01]' as a portable fallback.
extract_bits() { echo "$1" | grep -oE '[01]'; }

# ── Token storage ─────────────────────────────────────────────
# Expression is stored as parallel arrays of tokens:
#   tok_type : V=variable, O=operator, P=open-paren, Q=close-paren
#   tok_val  : operator symbol for O; var name for V; empty for P/Q
#   tok_neg  : 1 if this V token is negated; 0 otherwise
declare -a tok_type=("V")
declare -a tok_val=("p")
declare -a tok_neg=(0)

negate_next=0       # queue NOT for the next variable added
paren_depth=0       # track open parentheses
pending_open=0      # open-paren token queued before next var

# ── Count variables in token list ────────────────────────────
count_vars() {
    local c=0
    for t in "${tok_type[@]}"; do [[ "$t" == "V" ]] && (( c++ )); done
    echo "$c"
}

# ── Count unclosed parens ─────────────────────────────────────
count_open_parens() {
    local depth=0
    for t in "${tok_type[@]}"; do
        [[ "$t" == "P" ]] && (( depth++ ))
        [[ "$t" == "Q" ]] && (( depth-- ))
    done
    echo "$depth"
}

# ── Build human-readable expression string ────────────────────
expression_str() {
    local s=""
    for (( i=0; i<${#tok_type[@]}; i++ )); do
        case "${tok_type[$i]}" in
            V) (( ${tok_neg[$i]} )) && s+="!${tok_val[$i]}" || s+="${tok_val[$i]}" ;;
            O) s+=" ${tok_val[$i]} " ;;
            P) s+="(" ;;
            Q) s+=")" ;;
        esac
    done
    echo "$s"
}

# ── Core: evaluate and display the truth table ────────────────
build_and_show() {
    local n
    n=$(count_vars)

    # Validation
    if (( n == 0 )); then
        echo -e "${RED}No variables in expression.${RESET}"
        return 1
    fi
    local open
    open=$(count_open_parens)
    if (( open > 0 )); then
        echo -e "${RED}Expression has $open unclosed parenthesis(es). Close them first.${RESET}"
        return 1
    fi

    local expr
    expr=$(expression_str)
    local total=$(( 1 << n ))

    echo ""
    echo -e "${BOLD}${CYAN}============ Truth Table ============${RESET}"

    # Header: one column per variable
    local header=" "
    local var_order=()
    for (( i=0; i<${#tok_type[@]}; i++ )); do
        if [[ "${tok_type[$i]}" == "V" ]]; then
            local vname="${tok_val[$i]}"
            local neg="${tok_neg[$i]}"
            (( neg )) && header+="!${vname}  " || header+=" ${vname}  "
            var_order+=("$i")
        fi
    done
    header+="| Result"
    echo -e "${BOLD}${header}${RESET}"
    printf '%.0s-' $(seq 1 $(( ${#header} + 2 ))); echo ""

    # Accumulate rows for optional export
    local -a export_rows=()
    local csv_header=""
    for (( i=0; i<${#tok_type[@]}; i++ )); do
        [[ "${tok_type[$i]}" == "V" ]] && {
            local neg="${tok_neg[$i]}"
            (( neg )) && csv_header+="!${tok_val[$i]}," || csv_header+="${tok_val[$i]},"
        }
    done
    csv_header+="Result"

    for (( combo=0; combo<total; combo++ )); do
        local eval_str="" display=" " var_num=0

        for (( i=0; i<${#tok_type[@]}; i++ )); do
            case "${tok_type[$i]}" in
                V)
                    local raw=$(( (combo >> (n - 1 - var_num)) & 1 ))
                    local neg="${tok_neg[$i]}"
                    local val="$raw"
                    (( neg )) && val=$(( 1 - raw ))
                    display+=" ${val}  "
                    eval_str+="$val"
                    (( var_num++ ))
                    ;;
                O) eval_str+="${tok_val[$i]}" ;;
                P) eval_str+="(" ;;
                Q) eval_str+=")" ;;
            esac
        done

        local result=0
        (( result = ($eval_str) )) 2>/dev/null

        local result_col
        (( result )) && result_col="${GREEN}${BOLD}1${RESET}" || result_col="${RED}0${RESET}"
        printf "%-$((n*5+2))s|  %b\n" "$display" "$result_col"

        # Store plain row for export (strip display padding)
        local plain_vals=""
        for (( i=0; i<${#tok_type[@]}; i++ )); do
            if [[ "${tok_type[$i]}" == "V" ]]; then
                local v_num_e=0
                # recompute this var's value
                local var_idx=0
                for (( j=0; j<i; j++ )); do [[ "${tok_type[$j]}" == "V" ]] && (( var_idx++ )); done
                local r2=$(( (combo >> (n - 1 - var_idx)) & 1 ))
                local neg2="${tok_neg[$i]}"
                local v2="$r2"; (( neg2 )) && v2=$(( 1 - r2 ))
                plain_vals+="${v2},"
            fi
        done
        export_rows+=("${plain_vals}${result}")
    done

    echo ""
    echo -e "${CYAN}  Expression: $expr${RESET}"
    echo ""

    # Store for export
    _last_csv_header="$csv_header"
    _last_export_rows=("${export_rows[@]}")
    _last_expr="$expr"
    return 0
}

# ── Export last table ─────────────────────────────────────────
export_table() {
    if [[ -z "${_last_expr:-}" ]]; then
        echo -e "${RED}No table to export yet. Evaluate first.${RESET}"
        return
    fi
    echo -n "Save as (1) .txt  or  (2) .csv ? "
    read -r fmt
    local fname
    local safe_expr
    safe_expr=$(echo "$_last_expr" | tr -d ' !()' | tr '|&^' 'oax')
    local base="truth_${safe_expr}"

    case "$fmt" in
        1)
            fname="${base}.txt"
            {
                echo "Truth Table: $_last_expr"
                echo "Generated: $(date)"
                echo ""
                echo "$_last_csv_header" | tr ',' '   '
                printf '%.0s-' $(seq 1 40); echo ""
                for row in "${_last_export_rows[@]}"; do
                    echo "$row" | tr ',' '   '
                done
            } > "$fname"
            echo -e "${GREEN}Saved: $fname${RESET}"
            ;;
        2)
            fname="${base}.csv"
            {
                echo "Expression:,$_last_expr"
                echo "Generated:,$(date)"
                echo ""
                echo "$_last_csv_header"
                for row in "${_last_export_rows[@]}"; do
                    echo "$row"
                done
            } > "$fname"
            echo -e "${GREEN}Saved: $fname${RESET}"
            ;;
        *) echo -e "${RED}Cancelled.${RESET}" ;;
    esac
}

# ── Add operator + new variable ───────────────────────────────
add_operator() {
    local op="$1"
    local n
    n=$(count_vars)
    local maxn=${#var_names[@]}

    if (( n >= maxn )); then
        echo -e "${RED}Chain is full (max $maxn variables).${RESET}"
        return
    fi

    # If a ( is pending, insert it before the operator
    if (( pending_open )); then
        tok_type+=("O" "P" "V")
        tok_val+=("$op" "" "${var_names[$n]}")
        tok_neg+=(0 0 "$negate_next")
        pending_open=0
        (( paren_depth++ ))
    else
        tok_type+=("O" "V")
        tok_val+=("$op" "${var_names[$n]}")
        tok_neg+=(0 "$negate_next")
    fi

    local new_var="${var_names[$n]}"
    local neg_label=""
    (( negate_next )) && neg_label=" [!${new_var}]"
    negate_next=0
    echo -e "${GREEN}Added ${op} → new variable: ${new_var}${neg_label}${RESET}"
}

# ── Open parenthesis ──────────────────────────────────────────
open_paren() {
    local open
    open=$(count_open_parens)
    # A ( must come after an operator, so queue it for next add_operator call
    pending_open=1
    echo -e "${YELLOW}( queued — will wrap around the next operand group.${RESET}"
    echo -e "${YELLOW}  Add an operator (AND/OR/XOR) to place it.${RESET}"
}

# ── Close parenthesis ─────────────────────────────────────────
close_paren() {
    local open
    open=$(count_open_parens)
    if (( open == 0 )); then
        echo -e "${RED}No open parenthesis to close.${RESET}"
        return
    fi
    tok_type+=("Q")
    tok_val+=("")
    tok_neg+=(0)
    (( paren_depth-- ))
    echo -e "${YELLOW}Closed ).  Open parens remaining: $(count_open_parens)${RESET}"
}

# ── Toggle NOT on existing variable ───────────────────────────
toggle_neg() {
    local n
    n=$(count_vars)
    if (( n == 0 )); then echo -e "${RED}No variables yet.${RESET}"; return; fi

    printf "Toggle NOT on which variable? [ "
    local vi=1
    for (( i=0; i<${#tok_type[@]}; i++ )); do
        [[ "${tok_type[$i]}" == "V" ]] && { printf "%d=%s " $vi "${tok_val[$i]}"; (( vi++ )); }
    done
    printf "]: "
    read -r idx
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > n )); then
        echo -e "${RED}Invalid.${RESET}"; return
    fi
    local vi=0
    for (( i=0; i<${#tok_type[@]}; i++ )); do
        if [[ "${tok_type[$i]}" == "V" ]]; then
            (( vi++ ))
            if (( vi == idx )); then
                tok_neg[$i]=$(( ! ${tok_neg[$i]} ))
                local state; (( ${tok_neg[$i]} )) && state="ON" || state="OFF"
                echo -e "${YELLOW}NOT on '${tok_val[$i]}' → ${state}${RESET}"
                return
            fi
        fi
    done
}

# ── Undo last token ───────────────────────────────────────────
undo_last() {
    local len=${#tok_type[@]}
    if (( len <= 1 )); then
        echo -e "${RED}Nothing to undo (must keep at least p).${RESET}"
        return
    fi
    # Pop last token; if it's a V preceded by an O, pop the O too
    local last_type="${tok_type[$((len-1))]}"
    unset 'tok_type[-1]' 'tok_val[-1]' 'tok_neg[-1]'
    if [[ "$last_type" == "V" && ${#tok_type[@]} -gt 0 ]]; then
        local prev="${tok_type[-1]}"
        if [[ "$prev" == "O" || "$prev" == "P" ]]; then
            unset 'tok_type[-1]' 'tok_val[-1]' 'tok_neg[-1]'
            # If that P was preceded by an O, pop that too
            if [[ "${tok_type[-1]:-}" == "O" ]] && [[ "$prev" == "P" ]]; then
                unset 'tok_type[-1]' 'tok_val[-1]' 'tok_neg[-1]'
            fi
        fi
    elif [[ "$last_type" == "Q" ]]; then
        : # just popped the close paren, fine
    fi
    negate_next=0; pending_open=0
    echo -e "${YELLOW}Undone. Expression: $(expression_str)${RESET}"
}

# ── Reset ─────────────────────────────────────────────────────
reset_state() {
    tok_type=("V"); tok_val=("p"); tok_neg=(0)
    negate_next=0; paren_depth=0; pending_open=0
    unset _last_expr _last_csv_header _last_export_rows
    echo -e "${YELLOW}Reset. Starting fresh with p.${RESET}"
}

# ── Menu ──────────────────────────────────────────────────────
show_menu() {
    local n; n=$(count_vars)
    local expr; expr=$(expression_str)
    local open; open=$(count_open_parens)

    echo -e "${CYAN}------------------------------------------${RESET}"
    echo -e " ${BOLD}Expression:${RESET} ${expr}"
    echo -e " ${BOLD}Variables:${RESET}  $n  |  Open parens: $open"
    if (( negate_next ));  then echo -e " ${YELLOW}[NOT queued for next variable]${RESET}"; fi
    if (( pending_open )); then echo -e " ${YELLOW}[( queued — add an operator to place it]${RESET}"; fi
    echo -e "${CYAN}------------------------------------------${RESET}"
    echo -e " ${BOLD}1${RESET}  AND (&&)        ${BOLD}2${RESET}  OR (||)"
    echo -e " ${BOLD}3${RESET}  XOR (^)         ${BOLD}n${RESET}  NOT (!)"
    echo -e " ${BOLD}(${RESET}  Open paren      ${BOLD})${RESET}  Close paren"
    echo -e " ${BOLD}t${RESET}  Toggle NOT on existing variable"
    echo -e " ${BOLD}u${RESET}  Undo last       ${BOLD}r${RESET}  Reset"
    echo -e " ${BOLD}5${RESET}  Preview table   ${BOLD}e${RESET}  Export last table"
    echo -e " ${BOLD}q${RESET}  Quit            ${BOLD}[Enter]${RESET}  Evaluate"
    echo -e "${CYAN}------------------------------------------${RESET}"
    printf "Choice: "
}

# ── Banner ────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  +----------------------------------------------+"
echo "  |   TRUTH TABLE GENERATOR  v2                  |"
echo "  |   AND  OR  XOR  NOT  ( )  Export  Undo       |"
echo "  +----------------------------------------------+"
echo -e "${RESET}"
echo "  Variables auto-named p, q, r, … as you build."
echo "  Parentheses let you control grouping."
echo "  Export saves the last evaluated table to file."
echo ""

# ── Main loop ─────────────────────────────────────────────────
_last_expr=""
_last_csv_header=""
declare -a _last_export_rows=()

while true; do
    show_menu
    read -r choice

    case "$choice" in
        1) add_operator "&&" ;;
        2) add_operator "||" ;;
        3) add_operator "^"  ;;
        n|N)
            negate_next=$(( ! negate_next ))
            (( negate_next )) \
                && echo -e "${YELLOW}NOT queued: next variable will be negated.${RESET}" \
                || echo -e "${YELLOW}NOT cancelled.${RESET}"
            ;;
        "(") open_paren  ;;
        ")") close_paren ;;
        t|T) toggle_neg  ;;
        u|U) undo_last   ;;
        5)   build_and_show ;;
        e|E) export_table ;;
        r|R) reset_state ;;
        q|Q) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
        "")
            if build_and_show; then
                printf "${BOLD}Press Enter to keep building, e to export, or q to quit: ${RESET}"
                read -r cont
                case "$cont" in
                    q|Q) echo -e "${CYAN}Goodbye!${RESET}"; exit 0 ;;
                    e|E) export_table ;;
                esac
            fi
            ;;
        *) echo -e "${RED}Unknown option '${choice}'.${RESET}" ;;
    esac
done
