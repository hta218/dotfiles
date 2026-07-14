---
name: create-task
description: "Create a GitHub issue with project board integration"
---

Create a GitHub issue with full metadata and optional project board integration.

## Usage

- `create-task` - Interactive guided issue creation
- `create-task Add dark mode support` - Pre-fill the title/description from arguments

## Process

Follow these steps **in order**. Ask the user to gather all required info before creating anything.

### Step 1: Detect the GitHub owner

Try to infer the GitHub owner/org from the current repository:

```bash
gh repo view --json owner --jq '.owner.login'
```

- If this succeeds, use the detected owner and confirm with the user.
- If this fails (e.g., not in a git repo), ask the user for the GitHub owner/org name.

Store this as `<owner>` for all subsequent commands.

### Step 2: Ask which project

Fetch the list of projects dynamically:

gh project list --owner <owner> --format json --jq '.projects[] | "\(.number) \(.title)"'

Then ask the user to select a project. Include a "None (no project)" option.

### Step 3: Ask for repo, title, assignee, description, and content style

Ask these in a single question block if possible:

1. **Repository** - List repos from the owner. Run:
   gh repo list <owner> --json name --jq '.[].name' --limit 50
   Let user select one.

2. **Title** - Ask for the issue title (free text).

3. **Assignee** - Fetch collaborators/members dynamically:
   gh api repos/<owner>/<repo>/collaborators --jq '.[].login'
   Let user select from the list. Allow multiple selections. Include an "Unassigned" option.

4. **Description/Body** - Ask for the issue body content (free text). If user provides `$ARGUMENTS`, pre-fill from that. This is the **raw/brief** content that will be cleaned up (not padded) in the next step.

5. **Content Style Instructions** - Ask the user for custom guidelines on how to rewrite/enhance the description (free text). Examples:
   - "use checkboxes for action items"
   - "use simple english"
   - "no emojis"
   - "add acceptance criteria section"
   - "keep it concise"
   - "use bullet points"

   This is a single free-text field where the user writes their style preferences.

### Step 4: Clean up the title and description (stay minimal)

The raw title and description from Step 3 are brief/rough inputs. Before creating the issue, clean them up and apply the user's content style instructions. **Do NOT pad the description out.**

**Title:**
- Fix any grammar errors, typos, or awkward phrasing
- Make it concise, clear, and professional
- Follow GitHub issue title conventions (imperative mood, descriptive but short)

**Description:**
- Lightly clean it up (grammar, clarity, formatting) — stick to what the user actually provided
- **Only include sections that the user's input actually supports.** If they gave a Description and Steps to Reproduce, output exactly those two sections — nothing more
- **Do NOT invent or auto-add boilerplate sections** (e.g. Expected Behavior, Actual Behavior, Environment, Possible Cause, Root Cause, Acceptance Criteria, Impact) unless the user's raw input or their content-style instructions explicitly call for them
- **Do NOT fabricate details** the user didn't give (repro steps, environment values, causes, criteria). No filler, no guessing
- Keep it short. When in doubt, fewer sections is better
- Apply any style guidelines the user provided

Do NOT ask the user for approval of the cleaned-up content -- just apply the changes and proceed.

### Step 5: Ask for metadata

If a project was selected in Step 2, fetch the project's fields:

gh project field-list <PROJECT_NUMBER> --owner <owner> --format json

Then ask the user to set:

1. **Status** - Show the available status options from the project's SingleSelect fields (e.g., Todo, In Progress, In Review, Done, Closed).

2. **Priority** - Show available priority options if the project has a Priority field (e.g., High, Medium, Low). Include a "None" option.

3. **Labels** - Fetch labels from the selected repo:
   gh label list --repo <owner>/<repo> --json name --jq '.[].name'
   Let user select multiple. Include a "None" option.

4. **Milestone** - Fetch milestones from the selected repo:
   gh api repos/<owner>/<repo>/milestones --jq '.[].title'
   Let user select one. Include a "None" option.

5. **Issue Type** - Fetch issue types from the repo:
   gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") { issueTypes(first: 20) { nodes { id name } } } }'
   Let user select one (e.g., Task, Bug, Feature). Include a "None" option.

### Step 6: Create the issue

gh issue create \
  --repo <owner>/<repo> \
  --title "<title>" \
  --body "<body>" \
  --assignee "<assignee1>,<assignee2>" \
  --label "<label1>,<label2>" \
  --milestone "<milestone>"

Use a heredoc for the body to preserve formatting. Use the **cleaned-up description** from Step 4 (not the raw input from Step 3):
gh issue create --repo <owner>/<repo> --title "<title>" --assignee "<assignees>" --body "$(cat <<'EOF'
<body content>
EOF
)"

Omit `--assignee`, `--label`, `--milestone` flags if the user selected "None" for those.

### Step 7: Set issue type (if selected)

Get the issue node ID:
gh api repos/<owner>/<repo>/issues/<number> --jq '.node_id'

Then set the type:
gh api graphql -f query='mutation { updateIssueIssueType(input: { issueId: "<issue_node_id>", issueTypeId: "<type_id>"}) { issue { id } } }'

### Step 8: Add to project and set project fields

If a project was selected:

1. Add the issue to the project:
   gh project item-add <PROJECT_NUMBER> --owner <owner> --url <issue_url> --format json
   This returns the item ID.

2. Parse the GraphQL item ID from the JSON output (field: `id`).

3. Get the **numeric database ID** for the project board deep link:
   gh api graphql -f query='query { node(id: "<GRAPHQL_ITEM_ID>") { ... on ProjectV2Item { databaseId } } }' --jq '.data.node.databaseId'
   Save this numeric ID for the project board URL in Step 9.

4. Set **Status** on the project item:
   gh project item-edit \
     --id <ITEM_ID> \
     --project-id <PROJECT_ID> \
     --field-id <STATUS_FIELD_ID> \
     --single-select-option-id <STATUS_OPTION_ID>

5. Set **Priority** on the project item (if selected and field exists):
     --field-id <PRIORITY_FIELD_ID> \
     --single-select-option-id <PRIORITY_OPTION_ID>

### Step 9: Confirm

Output a summary of what was created:
- Issue URL: `https://github.com/<owner>/<repo>/issues/<number>`
- Project URL (if project was selected): `https://github.com/orgs/<owner>/projects/<project_number>?pane=issue&itemId=<numeric_item_id>&issue=<owner>%7C<repo>%7C<issue_number>`
- Repository
- Assignees
- Labels, Milestone, Type
- Project, Status, Priority

## Error Handling

- If `gh` CLI is not installed or not authenticated, inform the user and stop
- If any `gh` command fails, show the error to the user and ask how to proceed

## Important Notes

- Always use `--format json` when you need to parse output from `gh` commands.
- Use the project's internal IDs (from `field-list`) for `item-edit` commands, not display names.
- The `--project` flag on `gh issue create` does NOT set project field values -- you must use `gh project item-add` + `gh project item-edit` separately.
- For issue body, always use heredoc syntax to preserve multiline formatting.
- Keep issue descriptions minimal. Only include sections backed by what the user actually provided. Never auto-add boilerplate sections (Expected/Actual Behavior, Environment, Possible/Root Cause, Acceptance Criteria, Impact) or fabricate details unless the user asks for them.
