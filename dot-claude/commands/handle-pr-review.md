---
name: selrahcd:handle-pr-review
description: Fetch unresolved comments on Github PR and fix them
---

I've added comments on the PR, globally and on files.
Fetch the unresolved ones and add them to you todo list. Comments marked with a rocket are already handled.
I want you to handle them one by one.
For each one of them:
- understand the comment
- make the necessary changes
- create a new commit
- push it
- Reply to the comment with a link to the commit in the conversation. Start the comment with "🤖 [Claude Code] :"
- update your todo list


## Reply to comment

Use the following github cli command to reply to a comment.

```
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/OWNER/REPO/pulls/PULL_NUMBER/comments/COMMENT_ID/replies \
  -f body='Your reply text here'
 ```