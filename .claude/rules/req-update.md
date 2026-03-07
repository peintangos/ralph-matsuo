# Requirements Change Detection

When the user makes statements like the following, determine that a requirements change or addition may be needed, and suggest using the `/req-update` skill in the conversation:

- Mentions changing specifications or requirements (e.g., "I want to change...", "modify the spec for...", "this is no longer needed")
- Mentions adding new requirements or features (e.g., "I also want to add...", "I need a feature for...")
- Questions or reconsiders existing specifications (e.g., "is this right?", "I want to revisit...")

How to suggest:
1. First confirm the user's intent through conversation
2. Once the change/addition is clarified, suggest running `/req-update <description>`
3. If the user directly runs `/req-update`, proceed as-is
