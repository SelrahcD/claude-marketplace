---
name: handle-pr-review
description: Fetch unresolved comments on Github PR and fix them
---

# Handle PR Review

Fetch unresolved PR comments and fix them one by one.

## Steps

### 1. Get PR information

```bash
gh pr view --json number,url,headRepository
```

### 2. Fetch unresolved comments

Fetch comments not marked with 🚀 (already handled):

```bash
gh api repos/OWNER/REPO/pulls/PR_NUMBER/comments --jq '.[] | select(.body | contains("🚀") | not) | {id: .id, path: .path, line: .line, body: .body, in_reply_to_id: .in_reply_to_id}'
```

### 3. Create todo list

Add each unresolved comment to the todo list with:
- File path and line number
- Brief summary of what needs fixing

### 4. Process each comment

For each comment, in a single flow:

1. Read the file mentioned in the comment
2. Understand what change is requested
3. Edit the file to address the feedback
4. Commit with a descriptive message:
```bash
git add <file> && git commit -m "$(cat <<'EOF'
<description of fix>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```
5. Push immediately after commit:
```bash
git push
```
6. Reply to the comment with commit link:
```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/OWNER/REPO/pulls/PR_NUMBER/comments/COMMENT_ID/replies \
  -f body='🤖 [Claude Code] : Fixed in commit https://github.com/OWNER/REPO/commit/COMMIT_SHA'
```
7. Mark todo as completed before moving to next comment

### 5. Summary

After all comments are handled, show:
- Number of comments addressed
- List of commits created
