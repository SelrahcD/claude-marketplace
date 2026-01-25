# Story Splitting Techniques Catalog

Reference catalog of splitting dimensions with examples.

## By User/Who

### Personas

Different user types with different needs.

```json
{"category": "functional", "description": "Casual user adds shared expense quickly", "steps": ["Open group", "Tap quick add", "Enter amount", "Auto-split equally"], "acceptance_criteria": ["Quick add takes under 10 seconds", "Defaults to equal split", "All group members included"], "passes": false}
{"category": "functional", "description": "Meticulous user tracks expenses with full detail", "steps": ["Open group", "Add expense with itemization", "Assign items to specific people", "Attach receipt photo"], "acceptance_criteria": ["Can itemize expense line by line", "Each item assignable to different people", "Receipt image stored with expense"], "passes": false}
```

### Roles

Permission levels within the system.

```json
{"category": "functional", "description": "Group member views shared expenses", "steps": ["Open group", "See expense list", "See own balance"], "acceptance_criteria": ["All group expenses visible", "Balance shows amount owed/owing", "Cannot modify others' expenses"], "passes": false}
{"category": "functional", "description": "Group admin manages membership", "steps": ["Open group settings", "Add or remove members", "Archive group"], "acceptance_criteria": ["Admin can invite members", "Admin can remove members", "Admin can archive/delete group"], "passes": false}
```

### Expertise

Skill levels of users.

```json
{"category": "functional", "description": "New user creates first group with guidance", "steps": ["Open app", "See onboarding prompts", "Create group with help text", "Add first expense with tips"], "acceptance_criteria": ["Onboarding shown on first launch", "Tooltips explain each field", "Example expense shown"], "passes": false}
{"category": "functional", "description": "Power user manages multiple groups efficiently", "steps": ["See all groups dashboard", "Use keyboard shortcuts", "Bulk settle expenses"], "acceptance_criteria": ["Dashboard shows all groups at glance", "Keyboard navigation works", "Can settle multiple balances at once"], "passes": false}
```

## By Journey/What

### Workflow Steps

Sequential actions in a process.

```json
{"category": "functional", "description": "User adds expense to group", "steps": ["Open group", "Tap add expense", "Enter details", "Save"], "acceptance_criteria": ["Add button accessible", "Amount and description required", "Expense appears in list after save"], "passes": false}
{"category": "functional", "description": "User settles balance with group member", "steps": ["View balance with person", "Tap settle up", "Record payment", "Balance updated"], "acceptance_criteria": ["Settlement option available", "Can record cash or digital payment", "Both parties' balances update"], "passes": false}
```

### CRUD Operations

Data operations split separately.

```json
{"category": "functional", "description": "User views expense history", "steps": ["Open group", "See expense list", "Tap expense for details"], "acceptance_criteria": ["List shows date, description, amount", "Sorted by date descending", "Detail view shows full info"], "passes": false}
{"category": "functional", "description": "User creates new expense", "steps": ["Tap add expense", "Fill form", "Save"], "acceptance_criteria": ["Form validates required fields", "Expense persists after save", "Appears in expense list"], "passes": false}
{"category": "functional", "description": "User edits expense they created", "steps": ["Open expense", "Tap edit", "Modify fields", "Save changes"], "acceptance_criteria": ["Edit available for own expenses", "Changes reflected immediately", "Other users see updates"], "passes": false}
{"category": "functional", "description": "User deletes expense", "steps": ["Open expense", "Tap delete", "Confirm deletion"], "acceptance_criteria": ["Delete requires confirmation", "Expense removed from list", "Balances recalculated"], "passes": false}
```

### Happy/Sad Paths

Success vs error scenarios.

```json
{"category": "functional", "description": "User adds expense successfully", "steps": ["Enter valid amount", "Select participants", "Save expense"], "acceptance_criteria": ["Expense saved", "Confirmation shown", "Balance updated"], "passes": false}
{"category": "functional", "description": "User sees error for invalid expense", "steps": ["Enter invalid amount (negative/zero)", "Try to save", "See validation error", "Can correct and retry"], "acceptance_criteria": ["Validation message shown", "Form not cleared", "Can fix and resubmit"], "passes": false}
```

### Alternate Paths

Different ways to achieve the same goal.

```json
{"category": "functional", "description": "User settles up with cash", "steps": ["Select settle up", "Choose cash payment", "Record amount", "Mark as settled"], "acceptance_criteria": ["Cash option available", "Manual amount entry", "Balance clears on confirm"], "passes": false}
{"category": "functional", "description": "User settles up with payment app", "steps": ["Select settle up", "Choose Venmo/PayPal", "Deep link to payment app", "Confirm when done"], "acceptance_criteria": ["Payment app links available", "Redirects to correct app", "Returns to confirm settlement"], "passes": false}
```

## By Rules/How

### Business Rules

Complexity of validation logic.

```json
{"category": "functional", "description": "User splits expense equally", "steps": ["Add expense", "Select equal split", "System divides amount"], "acceptance_criteria": ["Amount divided by participant count", "Handles odd amounts (rounding)", "Each share shown clearly"], "passes": false}
{"category": "functional", "description": "User splits expense by percentage", "steps": ["Add expense", "Select percentage split", "Enter percentages", "System validates totals 100%"], "acceptance_criteria": ["Percentage input for each person", "Must total exactly 100%", "Validation error if not 100%"], "passes": false}
```

### Data Variations

Types of data supported.

```json
{"category": "functional", "description": "User adds expense in local currency", "steps": ["Add expense", "Amount in default currency", "Save"], "acceptance_criteria": ["Default currency from settings", "No conversion needed", "Display matches entry"], "passes": false}
{"category": "functional", "description": "User adds expense in foreign currency", "steps": ["Add expense", "Select currency", "Enter amount", "See converted value"], "acceptance_criteria": ["Currency selector available", "Exchange rate applied", "Original and converted amounts shown"], "passes": false}
```

### Conditions

Edge cases and special scenarios.

```json
{"category": "functional", "description": "User adds expense for subset of group", "steps": ["Add expense", "Deselect non-participants", "Split among selected only"], "acceptance_criteria": ["Can toggle each member", "At least one participant required", "Split only among selected"], "passes": false}
{"category": "functional", "description": "User adds expense paid by someone else", "steps": ["Add expense", "Change payer to other member", "Save expense"], "acceptance_criteria": ["Payer dropdown shows all members", "Can select any member as payer", "Balances reflect correct payer"], "passes": false}
```

## By Quality/How Well

### Fidelity

Level of polish and refinement.

```json
{"category": "functional", "description": "User sees expense list (basic)", "steps": ["Open group", "See plain list of expenses"], "acceptance_criteria": ["Expenses listed", "Date and amount visible", "Scrollable list"], "passes": false}
{"category": "quality", "description": "User sees expense list (polished)", "steps": ["Open group", "See grouped by date", "Pull to refresh", "Smooth animations"], "acceptance_criteria": ["Grouped by day/month", "Pull-to-refresh works", "Animations at 60fps"], "passes": false}
```

### Performance

Speed and responsiveness.

```json
{"category": "functional", "description": "User loads group expenses", "steps": ["Open group", "Wait for load", "See expenses"], "acceptance_criteria": ["Expenses load", "Spinner shown while loading", "List displays on completion"], "passes": false}
{"category": "quality", "description": "User loads group expenses instantly", "steps": ["Open group", "See cached expenses immediately", "Fresh data loads in background"], "acceptance_criteria": ["Cached data shown in <100ms", "Background refresh transparent", "No loading spinner for cached data"], "passes": false}
```

### Reliability

Error handling and resilience.

```json
{"category": "functional", "description": "User adds expense online", "steps": ["Add expense", "Submit to server", "See confirmation"], "acceptance_criteria": ["Server accepts expense", "Success confirmation shown", "Synced to other devices"], "passes": false}
{"category": "quality", "description": "User adds expense offline", "steps": ["Lose connection", "Add expense", "Queued for sync", "Syncs when online"], "acceptance_criteria": ["Expense saved locally", "Sync indicator shown", "Auto-syncs on reconnection"], "passes": false}
```

### Scale

Volume and load handling.

```json
{"category": "functional", "description": "User manages small group (5 people)", "steps": ["Create group", "Add 5 members", "Track expenses"], "acceptance_criteria": ["5 members supported", "All features work", "Balances calculated"], "passes": false}
{"category": "quality", "description": "User manages large trip group (50 people)", "steps": ["Create group", "Add 50 members", "Fast balance calculation"], "acceptance_criteria": ["50+ members supported", "Balance calc under 1s", "Member list virtualized"], "passes": false}
```

## By Context/Where

### Platform

Device or operating system.

```json
{"category": "context", "description": "User tracks expenses on iOS", "steps": ["Open on iPhone", "Full functionality"], "acceptance_criteria": ["App runs on iOS 15+", "All features work", "Native iOS feel"], "passes": false}
{"category": "context", "description": "User tracks expenses on Android", "steps": ["Open on Android", "Full functionality"], "acceptance_criteria": ["App runs on Android 10+", "All features work", "Material Design feel"], "passes": false}
```

### Form Factor

Screen size and layout.

```json
{"category": "context", "description": "User manages expenses on phone", "steps": ["Open on phone", "Single column layout", "Bottom navigation"], "acceptance_criteria": ["Fits phone screen width", "Easy thumb reach for navigation", "No horizontal scroll"], "passes": false}
{"category": "context", "description": "User manages expenses on tablet", "steps": ["Open on tablet", "Master-detail layout", "Groups and expenses side by side"], "acceptance_criteria": ["Uses tablet width effectively", "Group list and expense list visible together", "Optimized for landscape"], "passes": false}
```

### Interface

Input modes and interaction patterns.

```json
{"category": "functional", "description": "User enters expense with keyboard", "steps": ["Tap amount field", "Type on keyboard", "Tab to next field"], "acceptance_criteria": ["Numeric keyboard for amount", "Tab order logical", "Enter submits form"], "passes": false}
{"category": "functional", "description": "User enters expense with voice", "steps": ["Tap voice input", "Say 'Dinner 45 dollars split with Alice'", "See parsed expense"], "acceptance_criteria": ["Voice input available", "Parses amount and description", "Suggests participants from speech"], "passes": false}
```

### Environment

Conditions of use.

```json
{"category": "context", "description": "User adds expense at restaurant", "steps": ["Open app at table", "Quick add expense", "Minimal interaction"], "acceptance_criteria": ["Fast to open", "One-hand operation", "Works in dim lighting"], "passes": false}
{"category": "context", "description": "User reconciles expenses at home", "steps": ["Review all expenses", "Verify amounts", "Settle balances"], "acceptance_criteria": ["Full expense review available", "Edit capability for corrections", "Detailed balance breakdown"], "passes": false}
```

## Key Frameworks

### SPIDR (Mountain Goat Software)

- **S**pike - Research unknowns first
- **P**ath - Split by user paths
- **I**nterface - Progressive UI complexity
- **D**ata - Simplify data requirements
- **R**ules - Relax rules temporarily

### Hamburger Method (Gojko Adzic)

1. List technical layers/tasks
2. Define quality levels for each (low to high)
3. Select minimum acceptable quality per layer
4. Deliver thin vertical slice
5. Iterate with quality improvements

### INVEST Validation

- **I**ndependent - Delivers value alone
- **N**egotiable - Scope can flex
- **V**aluable - User gets something
- **E**stimable - Team can size it
- **S**mall - Fits in a sprint
- **T**estable - Can verify it works
