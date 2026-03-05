> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 2: Users and Permissions
> **Type:** Supplemental Reading
> **Source:** [Selecting Secure Passwords – Microsoft TechNet](https://learn.microsoft.com/en-us/previous-versions/tn-archive/cc875839(v=technet.10))

---

## Why Passwords Are Still Relevant

Despite alternatives like [[Biometrics]], [[Smart Cards]], and [[One-Time Passwords (OTP)]], most organizations still rely on username/password [[Authentication]]. Users tend to reuse simple passwords (birthdays, names) — making them easy to attack.

---

## Common Password Attack Methods

| Attack | Description |
|---|---|
| **[[Guessing Attack]]** | Attacker manually tries likely words (names, cities, sports teams) |
| **[[Online Dictionary Attack]]** | Automated tool tries words from a text file against a live login |
| **[[Offline Dictionary Attack]]** | Attacker gets a copy of the [[Password Hashing\|password hash]] file and cracks it locally |
| **[[Brute Force Attack]]** | Generates and compares all possible password hashes — very fast offline |

Strong passwords slow down or defeat all of these methods.

---

## Windows Password Storage

Windows never stores passwords in [[Plaintext]]. Two [[Password Hashing|hash]] types are used:

### LAN Manager (LM) Hash — Legacy, Weak

- Converts all characters to **uppercase** → eliminates case sensitivity
- Pads password to exactly **14 characters**, then splits into two **7-character chunks**
- Each chunk is hashed separately → easier to crack in two parts
- Most cracking tools start with LM hashes, then vary letter casing to find the real password

### [[NTLM]] Hash — Modern, Stronger

- Supports the full **Unicode character set**
- Calculated using **[[MD4]]** hashing algorithm
- Stored in **[[Active Directory]]** or the local **[[SAM (Security Accounts Manager)]]** database
- Orders of magnitude harder to [[Brute Force Attack|brute force]] than LM hashes

---

## What Makes a Strong Password

Windows defines a strong password as one using characters from **at least 3 of these 5 groups**:

| Group | Examples |
|---|---|
| Lowercase letters | a, b, c … |
| Uppercase letters | A, B, C … |
| Numerals | 0–9 |
| Symbols | `! @ # $ % ^ & * ( )` etc. |
| Unicode characters | €, Γ, ƒ, λ |

> ⚠️ Spaces do **not** count toward any group.

For **admin or sensitive accounts**, use characters from **4 or 5 groups**.

---

## Passphrases over Passwords

A **[[Passphrase]]** is longer and often easier to remember than a complex password:

- Example: `I re@lly want to buy 11 Dogs!`
- Over 20 characters → most cracking tools assume max 14 characters
- Includes 4 of 5 groups
- Windows supports up to **128 characters** in passwords

> Longer passwords (>14 characters) can offer the strongest protection even without full complexity. Combining **length and complexity** is the most secure approach.

---

## Entropy

**[[Entropy]]** = randomness/unpredictability in a password. Higher entropy = harder to crack.

- Use symbols beyond the typical "upper row" (`! @ # $ % ^ & *`) — e.g. `[ ] { } < >` are less commonly tested
- **ALT key combinations** (Unicode characters) increase entropy significantly for sensitive accounts
- Placing non-alphanumeric characters **throughout** the password (not just in position 8) maximizes complexity

---

## Password Policy Recommendations

- Enforce **minimum length** and **[[Password Complexity]]** requirements organization-wide
- Sensitive accounts (admins, executives) should use longer, more complex [[Passphrase|passphrases]]
- Communicate password requirements clearly to end users
- Do not use example passwords from documentation — attackers may include them in their tools

> 📎 See also: [[Passwords]] | [[Host Files]] | [[DNS Registration and Expiration]]

---

**Tags:** #google-it-support #operating-systems #security #passwords #windows #policy #cybersecurity
