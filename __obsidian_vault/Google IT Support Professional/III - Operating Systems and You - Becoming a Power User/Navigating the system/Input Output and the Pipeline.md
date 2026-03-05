> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 1: Navigating the System

---

## I/O Streams (both platforms)

Every process has three streams:

| Stream | Number | Purpose |
|---|---|---|
| **Standard In (stdin)** | 0 | Input — keyboard input flows into the process |
| **Standard Out (stdout)** | 1 | Output — process results flow to the screen |
| **Standard Error (stderr)** | 2 | Error messages — separate from normal output |

## Redirection Operators

| Operator | Effect | Windows Example | Linux Example |
|---|---|---|---|
| `>` | Redirect stdout (**overwrites**) | `echo woof > dog.txt` | `echo woof > dog.txt` |
| `>>` | Redirect stdout (**appends**) | `echo woof >> dog.txt` | `echo woof >> dog.txt` |
| `<` | Redirect **stdin** from a file | — | `cat < file_input.txt` |
| `2>` | Redirect **stderr** to a file | `rm secure_file 2> errors.txt` | `ls /fake_dir 2> errors.txt` |
| `2> $null` / `2> /dev/null` | Discard error messages | `rm secure_file 2> $null` | `ls /fake_dir 2> /dev/null` |

**Note:** Windows uses `$null` (a PowerShell variable), Linux uses `/dev/null` (a special file) — both act as a "black hole" for unwanted output.

## The Pipeline: `|`

Sends the **stdout** of one command as **stdin** to the next command.

| Platform | Example |
|---|---|
| Windows ([[PowerShell]]) | `cat words.txt \| sls st` |
| Linux (Bash) | `ls -la /etc \| grep bluetooth` |

Pipes can be chained with redirection:

```powershell
cat words.txt | sls st > st_words.txt
```

## Further Reading (Windows)

```powershell
Get-Help about_redirection
```

---

**Tags:** #google-it-support #operating-systems #windows #linux #cli #powershell #bash
