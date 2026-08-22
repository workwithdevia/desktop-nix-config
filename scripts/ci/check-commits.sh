# ============================================================
# ONLY VALIDATE MERGE REQUESTS
# ============================================================

if [[ -z "${CI_MERGE_REQUEST_IID:-}" ]]; then
    echo "Mode: Branch pipeline"
    echo
    echo "✓ Commit message validation is only required for Merge Requests."
    echo "✓ Skipping commit message validation."
    exit 0
fi

BASE_SHA="${CI_MERGE_REQUEST_DIFF_BASE_SHA}"
HEAD_SHA="${CI_COMMIT_SHA}"

echo "Mode: Merge Request"
echo "Base: $BASE_SHA"
echo "Head: $HEAD_SHA"
echo

mapfile -t COMMITS < <(
    git rev-list \
        --reverse \
        --no-merges \
        "$BASE_SHA..$HEAD_SHA"
)
