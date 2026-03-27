Search Hacker News discussions for a keyword and summarize the sentiment from comments.

Arguments: the keyword or topic to search for (required).

## Steps

1. **Search stories** — Use WebFetch to call the Hacker News Algolia API:
   `https://hn.algolia.com/api/v1/search?query=<KEYWORD>&tags=story&hitsPerPage=5`
   Pick the top 5 most relevant stories (sort by points + num_comments).

2. **Fetch comments** — For each story, use WebFetch to get its comment tree:
   `https://hn.algolia.com/api/v1/items/<objectID>`
   Collect comment text from the response (traverse `children` recursively, keep only `text` fields). Limit to ~50 top-level comments per story to stay within context.

3. **Analyze & summarize** — Read through all collected comments and produce:
   - **Stories found**: list each story title, URL, points, and comment count
   - **Overall sentiment**: one-line summary (positive / negative / mixed / neutral)
   - **Key themes**: 3-5 bullet points capturing the main opinions, concerns, or praise
   - **Notable quotes**: 2-3 representative comments (keep them short)
   - **Controversy**: any divisive points where opinions strongly diverge

## Rules

- Write the summary in the same language the user used to invoke the skill
- If no stories are found, say so and suggest alternative keywords
- Do not fabricate comments — only summarize what was actually fetched
- Keep the output concise and scannable
