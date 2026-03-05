> **Course:** [[Google IT Support Professional]]
> **Section:** [[III - Operating Systems and You: Becoming a Power User]] → Module 3: Package and Software Management
> **Type:** Supplemental Reading

---

## How Apps Are Distributed

Mobile apps reach devices through two main channels: **public app stores** and **private/enterprise distribution**. Both iOS and Android have distinct ecosystems for each.

---

## iOS – Apple App Distribution

### Apple App Store (Public)

- Reaches millions of devices worldwide (iPhone, iPad, Apple Watch)
- Managed via **App Store Connect** — handles pricing, payments, beta testing, analytics
- Developers must register through the **Apple Developer Program**
- All apps go through a rigorous **review process** based on Apple's guidelines (safety, SDKs, trademarks, copyright, data privacy, etc.)
- An **appeals process** exists for rejected apps
- Development recommended via **Xcode IDE** or **Ad Hoc**

### Custom Apple Apps (Private/Enterprise)

Organizations can distribute private apps for internal use (employees, students, partners, franchisees). Two managed platforms are available:

| Platform | Target | Key Features |
|---|---|---|
| **Apple School Manager** | Educational institutions | Private app distribution, volume purchasing with educator discounts, student/staff account creation, automatic device enrollment |
| **Apple Business Manager** | Businesses | Private app distribution, volume purchasing, automatic [[MDM]]-based app deployment to registered devices |

Apps are visible to audience groups via the **Apps and Books** section of these platforms.

### Outside Official Channels

Developers can distribute "trusted developer" apps from websites or private file shares using their **Apple Developer ID certificate** and Apple's **notarization process** — without going through the App Store.

---

## Android – Google Play Distribution

### Google Play Store (Public)

- Hosts 2M+ apps with 140B+ downloads per year
- Built-in safety protections require developers to meet high safety standards
- Development uses **Android Studio** (official IDE)
- Apps compiled as **APK files** via **Android App Bundle**, which also enables automatic APK generation for different device types

**Publishing process:**
1. Create a Google Play developer account
2. Use **Google Play Console** to create the app listing
3. Agree to Developer Program Policies and Terms of Service
4. Follow the Dashboard through: store listing → pre-release → testing → review submission → publish

### Custom Android Apps (Enterprise)

Large organizations use **Managed Google Play** to host and deploy private apps:

- Enterprise customers operate their own Play Store (public and/or private)
- Access can be restricted to specific users or groups
- **Google Play Custom App Publishing API** enables publishing private apps that **cannot be converted to public** — they remain private permanently
- Verification for private apps can take as little as **5 minutes**

**IT Support workflow for managed Android:**
- Select and approve apps via the organization's managed Google Play
- Ensure employee devices use the organization's managed Google Play account
- Use **EMM (Enterprise Mobility Manager)** to deploy apps to devices
- For **BYOD devices**: create a **work profile** so employees can access managed Play separately from personal apps

### Outside Official Channels

Google's open platform allows alternative Android app stores, including APKMirror, Aurora Store, Amazon Appstore, F-Droid, and others.

---

> 📎 See also: [[Mobile App Packages]] | [[Mobile Users and Accounts]] | [[MDM]]

---

**Tags:** #google-it-support #operating-systems #mobile #android #ios #software #packages #enterprise #mdm #security
