#!/usr/bin/env bash
# ============================================================
#  .erf/.epf <-> XML  (Linux / macOS)
#  გამოყენება:
#    ./dump-load.sh dump  /path/Report.erf  /path/src/Report
#    ./dump-load.sh load  /path/src/Report  /path/Report.erf
# ============================================================
set -euo pipefail

V8="${V8:-/opt/1cv8/x86_64/8.3.24.1548/1cv8}"
IB="${IB:-/work/scratch_ib}"
V8USER="${V8USER:-Администратор}"
V8PWD="${V8PWD:-}"

MODE="${1:-}"; A="${2:-}"; B="${3:-}"

usage() { echo "Usage: $0 {dump|load} <src> <dst>"; exit 2; }
[[ -n "$MODE" && -n "$A" && -n "$B" ]] || usage
[[ -x "$V8" ]] || { echo "1cv8 ვერ მოიძებნა: $V8 (დააყენე V8 ცვლადი)"; exit 3; }

# set -e-ს გამო ჩავარდნილი ბრძანება სკრიპტს მაშინვე შეაჩერებდა და შეცდომის
# დამუშავებამდე ვერ მივიდოდით — ამიტომ გასვლის კოდს ცალკე ვიჭერთ.
RC=0
LOG=""

case "$MODE" in
  dump)
    mkdir -p "$B"; LOG="$B/_dump.log"
    "$V8" DESIGNER /F "$IB" /N "$V8USER" /P "$V8PWD" \
      /DisableStartupMessages \
      /DumpExternalDataProcessorOrReportToFiles "$B" "$A" -Format Hierarchical \
      /Out "$LOG" -NoTruncate || RC=$?
    ;;
  load)
    LOG="$A/_load.log"
    "$V8" DESIGNER /F "$IB" /N "$V8USER" /P "$V8PWD" \
      /DisableStartupMessages \
      /LoadExternalDataProcessorOrReportFromFiles "$A" "$B" \
      /Out "$LOG" -NoTruncate || RC=$?
    ;;
  *) usage ;;
esac

if [[ $RC -ne 0 ]]; then
  echo "[FAIL] exit code $RC"; cat "$LOG" || true; exit $RC
fi
echo "[OK] $MODE დასრულდა. ლოგი: $LOG"
