---
name: Explain Code
description: Explain how the selected code works
interaction: chat
opts:
  alias: explain
  modes:
    - v
  auto_submit: true
---

## user

Explain how this code works in detail. Cover:

1. **Purpose** - What does this code accomplish?
2. **Flow** - Step by step execution
3. **Key concepts** - Important patterns or techniques used
4. **Edge cases** - What happens in unusual situations?

```${context.filetype}
${context.code}
```
