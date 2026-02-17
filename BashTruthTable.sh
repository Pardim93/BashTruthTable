#!/bin/bash
# ============================================================
#  Truth Table Generator — Upgraded
#  Supports: AND (&&), OR (||), NOT (!) via negation flags
#  Variables auto-named: p, q, r, s, t, …
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'

declare -a ops=()    # operators between operands, e.g. ("&&" "||")
declare -a negs=(0)  # per-operand negation flag (0=plain, 1=negated)
negate_next=0        # queue negation for the next operand added

var_names=(p q r s t u v w x y)

num_operands() { echo $(( ${#ops[@]} + 1 )); }

build_and_show() {
    local n
    n=$(num_operands)
    local maxn=${#var_names[@]}

    if (( n > maxn )); then
        echo -e "${RED}Maximum chain length reached ($maxn operands).${RESET}"
        return
    fi

    echo ""
    echo -e "${BOLD}${CYAN}============ Truth Table ============${RESET}"

    # Header
    local header=" "
    for (( i=0; i<n; i++ )); do
        local vname="${var_names[$i]}"
        local neg="${negs[$i]:-0}"
        (( neg )) && header+="!${vname}  " || header+=" ${vname}  "
    done
    header+="| Result"
    echo -e "${BOLD}${header}${RESET}"
    printf '%.0s-' $(seq 1 $(( ${#header} + 2 )))
    echo ""

    # Brace-expansion string: {0..1}"&&"{0..1} etc.
    local brace_expr=""
    for (( i=0; i<n; i++ )); do
        (( i > 0 )) && brace_expr+="\"${ops[$((i-1))]}\""
        brace_expr+="{0..1}"
    done

    # Iterate every truth assignment
    for combo in $(eval "echo $brace_expr"); do
        # Extract raw bit values in order (grep digits only)
        local bits
        bits=$(echo "$combo" | grep -oP '[01]')
        readarray -t bit_arr <<< "$bits"

        local display=" "
        local eval_expr=""

        for (( i=0; i<n; i++ )); do
            local raw="${bit_arr[$i]}"
            local neg="${negs[$i]:-0}"
            local val="$raw"
            (( neg )) && val=$(( 1 - raw ))
            display+=" ${val}  "
            (( i > 0 )) && eval_expr+=" ${ops[$((i-1))]} "
            eval_expr+="$val"
        done

        local result=0
        (( result = ( $eval_expr ) )) 2>/dev/null

        local result_col
        if (( result )); then
            result_col="${GREEN}${BOLD}1${RESET}"
        else
            result_col="${RED}0${RESET}"
        fi

        printf "%-$((n*5+2))s|  %b\n" "$display" "$result_col"
    done
    echo ""

    # Expression legend
    local legend="  Expression: "
    for (( i=0; i<n; i++ )); do
        local neg="${negs[$i]:-0}"
        (( i > 0 )) && legend+=" ${ops[$((i-1))]} "
        (( neg )) && legend+="!${var_names[$i]}" || legend+="${var_names[$i]}"
    done
    echo -e "${CYAN}${legend}${RESET}"
    echo ""
}

show_menu() {
    local n
    n=$(num_operands)
    local ops_str="(none - only p so far)"
    (( ${#ops[@]} > 0 )) && ops_str="${ops[*]}"

    # Build readable current expression
    local expr_str=""
    for (( i=0; i<n; i++ )); do
        local neg="${negs[$i]:-0}"
        (( i > 0 )) && expr_str+=" ${ops[$((i-1))]} "
        (( neg )) && expr_str+="!${var_names[$i]}" || expr_str+="${var_names[$i]}"
    done

    echo -e "${CYAN}------------------------------------------${RESET}"
    echo -e " ${BOLD}Expression:${RESET} $expr_str"
    echo -e " ${BOLD}Operands:${RESET}   $n  / Variables: ${var_names[*]:0:$n}"
    if (( negate_next )); then
        echo -e " ${YELLOW}[NOT queued] -- next operand will be negated${RESET}"
    fi
    echo -e "${CYAN}------------------------------------------${RESET}"
    echo -e " ${BOLD}1${RESET}  Add AND (&&)"
    echo -e " ${BOLD}2${RESET}  Add OR  (||)"
    echo -e " ${BOLD}3${RESET}  Queue NOT for next operand"
    echo -e " ${BOLD}4${RESET}  Toggle NOT on an existing operand"
    echo -e " ${BOLD}5${RESET}  Preview table"
    echo -e " ${BOLD}r${RESET}  Reset"
    echo -e " ${BOLD}q${RESET}  Quit"
    echo -e " ${BOLD}[Enter]${RESET}  Evaluate & show final truth table"
    echo -e "${CYAN}------------------------------------------${RESET}"
    printf "Choice: "
}

toggle_prev_neg() {
    local n
    n=$(num_operands)
    printf "Toggle NOT on which variable? "
    printf "[ "
    for (( i=0; i<n; i++ )); do
        printf "%d=%s " $(( i+1 )) "${var_names[$i]}"
    done
    printf "]: "
    read -r idx
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > n )); then
        echo -e "${RED}Invalid index.${RESET}"
        return
    fi
    local i=$(( idx - 1 ))
    negs[$i]=$(( ! ${negs[$i]:-0} ))
    local state
    (( ${negs[$i]} )) && state="ON (negated)" || state="OFF (normal)"
    echo -e "${YELLOW}NOT on '${var_names[$i]}' is now: ${state}${RESET}"
}

add_operator() {
    local op="$1"
    local maxn=${#var_names[@]}
    local n
    n=$(num_operands)

    if (( n >= maxn )); then
        echo -e "${RED}Chain is full (max $maxn operands).${RESET}"
        return
    fi

    ops+=("$op")
    negs+=("$negate_next")
    local new_var="${var_names[$n]}"
    local neg_label=""
    (( negate_next )) && neg_label=" [negated as !${new_var}]"
    negate_next=0
    echo -e "${GREEN}Added ${op}. New operand: ${new_var}${neg_label}${RESET}"
}

reset_state() {
    ops=()
    negs=(0)
    negate_next=0
    echo -e "${YELLOW}Reset. Chain cleared.${RESET}"
}

# ── Banner ────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  +------------------------------------------+"
echo "  |   TRUTH TABLE GENERATOR  -- Upgraded     |"
echo "  |   Build: p && q,  !p || q,  p && q || r  |"
echo "  +------------------------------------------+"
echo -e "${RESET}"
echo "  Start with 'p'. Each AND/OR adds the next variable."
echo "  Use NOT (option 3) before adding an operand to negate it."
echo "  Or toggle NOT on any existing operand with option 4."
echo ""

# ── Main loop ─────────────────────────────────────────────────
while true; do
    show_menu
    read -r choice

    case "$choice" in
        1) add_operator "&&" ;;
        2) add_operator "||" ;;
        3)
            negate_next=$(( ! negate_next ))
            if (( negate_next )); then
                echo -e "${YELLOW}NOT queued: the next operand you add will be negated.${RESET}"
            else
                echo -e "${YELLOW}NOT cancelled.${RESET}"
            fi
            ;;
        4) toggle_prev_neg ;;
        5) build_and_show ;;
        r|R) reset_state ;;
        q|Q)
            echo -e "${CYAN}Goodbye!${RESET}"
            exit 0
            ;;
        "")
            build_and_show
            printf "${BOLD}Press Enter to keep building, or q to quit: ${RESET}"
            read -r cont
            [[ "$cont" == "q" || "$cont" == "Q" ]] && {
                echo -e "${CYAN}Goodbye!${RESET}"
                exit 0
            }
            ;;
        *) echo -e "${RED}Unknown option '${choice}'. Please try again.${RESET}" ;;
    esac
done
