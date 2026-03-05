> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## Command History

Every command entered in [[PowerShell]] or Bash is saved to memory and a special file. This lets you reuse previous commands without retyping them. The commands work **identically** on both platforms.

### Navigating History

| Action | Windows (PowerShell) | Linux (Bash) |
|---|---|---|
| Scroll through previous commands | Up / Down arrow keys | Up / Down arrow keys |
| View full history list | `history` | `history` |
| Search history (reverse search) | **Ctrl+R** | **Ctrl+R** |
| Search history (older PowerShell) | `#<partial command>` + Tab | — |

### Clearing the Screen

```
clear
```

Works on both platforms. Clears the visual output — does **not** erase your command history.

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash
