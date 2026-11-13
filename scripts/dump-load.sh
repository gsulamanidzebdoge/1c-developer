#!/usr/bin/env bash
# ============================================================
#  .erf/.epf <-> XML  (Linux / macOS)
#  გამოყენება:
#    ./dump-load.sh dump  /path/Report.erf               /path/src/Report
#    ./dump-load.sh load  /path/src/Report/Report.xml    /path/Report.erf
#    ./dump-load.sh load  /path/src/Report               /path/Report.erf   (კატალოგში ერთადერთი .xml)
#
#  IB — ბაზა იმ კონფიგურაციით, რომლისთვისაც დამუშავება დაიწერა: ცარიელ
#  ბაზაში დაშლისას ბმულოვანი ტიპები (CatalogRef.* და სხვ.) შეცდომის გარეშე იკარგება.
#  V8 — 1cv8-ის გზა; Linux-ზე, თუ არ არის მითითებული, აიღება უახლესი
#  /opt/1cv8/x86_64/<ვერსია>/1cv8. macOS-ზე V8 ხელით მიუთითე.
# ============================================================
set -euo pipefail

IB="${IB:-/work/ib_copy}"
# V8USER / V8PWD — მხოლოდ იმ ბაზისთვის, რომელშიც მომხმარებლები არსებობს: მომხმარებლების
# გარეშე ბაზაში ზედმეტი /N შეცდომას იძლევა „Пользователь ИБ не идентифицирован".
V8USER="${V8USER:-}"
V8PWD="${V8PWD:-}"
AUTH=()
if [[ -n "$V8USER" ]]; then AUTH=(/N "$V8USER" /P "$V8PWD"); fi
if [[ -z "${V8:-}" ]]; then
  V8="$(ls -d /opt/1cv8/x86_64/8.3.*/1cv8 2>/dev/null | sort -V | tail -n 1 || true)"
fi

MODE="${1:-}"; A="${2:-}"; B="${3:-}"

usage() { echo "Usage: $0 {dump|load} <src> <dst>"; exit 2; }
[[ -n "$MODE" && -n "$A" && -n "$B" ]] || usage
[[ -n "$V8" && -x "$V8" ]] || { echo "1cv8 ვერ მოიძებნა: '${V8}' (დააყენე V8 ცვლადი)"; exit 3; }
echo "platform: $V8"

# set -e-ს გამო ჩავარდნილი ბრძანება სკრიპტს მაშინვე შეაჩერებდა და შეცდომის
# დამუშავებამდე ვერ მივიდოდით — ამიტომ გასვლის კოდს ცალკე ვიჭერთ.
RC=0
LOG=""

case "$MODE" in
  dump)
    mkdir -p "$B"; LOG="${B%/}.dump.log"
    "$V8" DESIGNER /F "$IB" ${AUTH[@]+"${AUTH[@]}"} \
      /DisableStartupDialogs /DisableStartupMessages \
      /DumpExternalDataProcessorOrReportToFiles "$B" "$A" -Format Hierarchical \
      /Out "$LOG" -NoTruncate || RC=$?
    ;;
  load)
    # პლატფორმა ელის ძირეულ XML-ფაილს; კატალოგის შემთხვევაში მასში ერთადერთ .xml-ს ვეძებთ
    ROOT="$A"
    if [[ -d "$A" ]]; then
      shopt -s nullglob; XMLS=("${A%/}"/*.xml); shopt -u nullglob
      [[ ${#XMLS[@]} -eq 1 ]] || { echo "'$A'-ში მოსალოდნელია ზუსტად ერთი .xml, ნაპოვნია ${#XMLS[@]}"; exit 2; }
      ROOT="${XMLS[0]}"
    fi
    LOG="${B}.load.log"
    "$V8" DESIGNER /F "$IB" ${AUTH[@]+"${AUTH[@]}"} \
      /DisableStartupDialogs /DisableStartupMessages \
      /LoadExternalDataProcessorOrReportFromFiles "$ROOT" "$B" \
      /Out "$LOG" -NoTruncate || RC=$?
    ;;
  *) usage ;;
esac

if [[ $RC -ne 0 ]]; then
  echo "[FAIL] exit code $RC"; cat "$LOG" || true; exit $RC
fi
echo "[OK] $MODE დასრულდა. ლოგი: $LOG"
