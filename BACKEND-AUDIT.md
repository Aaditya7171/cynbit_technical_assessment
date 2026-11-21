# Backend Audit: Cynbit

## Overview

For this assessment, I reviewed Cynbit's public website to understand how some of its backend-related features work. I focused on the contact form, the BitElevate payment flow, public-page caching, and basic security settings.

I looked at the pages, HTTP response headers, and JavaScript files available in the browser. I also used Chrome DevTools and REA to help inspect the client-side code.

This review is based on what the website exposes publicly. I didn't have access to the actual backend source code, database, or server configuration, so I've separated what I found from what I think could be improved.

## 1. What I could understand about the backend

From the public files and response headers, the website appears to use **Next.js App Router**, **React Server Components**, and **Vercel**. Some forms use **Next.js Server Actions** rather than a separately documented REST API. BitElevate uses **Cashfree** for its checkout flow.

The visible flow looks roughly like this:

```text
Browser
  → Next.js pages and forms (served through Vercel)
  → Server Actions for form submissions and checkout
  → Payment verification for BitElevate

Database, authentication checks, and background jobs:
couldn't find from the public website
```

### API behavior and data passed from the frontend

I found these actions and fields in the publicly delivered JavaScript:

- **`submitInquiry`**: The contact form sends `fullName`, `email`, `company`, `industry`, and `message` as `FormData`. The frontend expects a success result.
- **`submitCandidateApplication`**: The careers form sends applicant information, `jobId`, and education details. The frontend handles success, error, and duplicate-application responses, including a possible tracking URL.
- **`createBitelevateCashfreeOrder`**: The enrollment form sends contact information and the selected program details. The frontend expects an order ID and a Cashfree payment session on success.
- **`verifyBitelevatePayment`**: The frontend passes an order ID and token and handles a result containing fields such as `success`, `orderStatus`, and `error`.

These are **client-side expectations**, not proof of the exact validation rules or response schemas on the server. I would validate incoming data on the server, especially applicant details and payment-related inputs, instead of trusting the frontend alone. This is a recommendation, not a claim that website lacks validation.

## 2. Findings and suggested improvements

### 1. Contact form error handling

**What I noticed:** In the contact form's JavaScript, the loading state is enabled before the submission action runs and cleared afterward. The inspected handler doesn't have a local `catch` or `finally` around the awaited action.

**Why it matters:** If the request rejects unexpectedly, the code that clears the loading state might not run and The form could remain disabled or show an error without letting the user retry normally. I found this in the code from dev tools; I didn't reproduce the failure on the live site.

**How I'd improve it:** I'd use `try/catch/finally` so the loading state is always reset, show a useful error, and keep the user's entered values. For retries, I'd also consider a server-side idempotency key or a status check, because a failed response doesn't always mean the form wasn't saved.

```javascript
// Like this -->
setLoading(true);
try {
  const result = await submitForm(formData);
  // handLe success or a Returned validation Error
} catch {
  showError("Could not confirm the Submission. Please Try again.");
} finally {
  setLoading(false);
}
```

You can See [recovery.mjs](Examples/recovery.mjs) for an example

### 2. Payment verification messages

**What I noticed:** While checking the BitElevate, I found a branch that shows **"Your account was not charged"** when verification returns an unsuccessful result. Another branch handles an `ACTIVE` order with a similar message. A rejected verification request, however, already shows a more neutral error.

**Why it matters:** An unsuccessful verification result and a confirmed failed payment aren't always the same thing. If a payment is still pending, a definite message about not being charged could encourage the customer to try paying again.

**How I'd improve it:** I'd make the backend distinguish **paid**, **failed**, and **pending/unknown** results using authoritative Cashfree information. I'd only confirm a failed payment when the provider's result supports it. I'd also use database uniqueness and transactions so repeated payment notifications don't create duplicate enrollments.

```javascript
// Simplified UI handling for a server-verified payment state
if (status === "PAID") {
  showSuccess("Payment confirmed.");
} else if (status === "FAILED") {
  showError("Payment failed.");
} else {
  showMessage("Payment status is still being checked.");
}
```

The [payment-idempotency.sql](Examples/payment-idempotency.sql) example shows a possible database-side approach as a design example

### 3. Caching and performance

**What I noticed:** Many public pages, including the blog, careers, and case studies, returned `no-store` cache directives and a Vercel cache `MISS`. Some other marketing pages were already cached and lot of public-page responses had the no-store/MISS combination.

**Why it matters:** If a page shows the same published content to everyone, generating it for every request may create unnecessary work. 

**How I'd improve it:** I'd check which pages are truly public and identical for all visitors, then use caching with revalidation for those pages. Content could be refreshed when an article or job listing changes. I'd keep application data, payment details, and user-specific responses out of shared caches.

### 4. Security headers

**What I noticed:** The inspected HTML responses were missing several recommended headers, including Content-Security-Policy, X-Content-Type-Options, and explicit framing and referrer policies.

**Why it matters:** These headers add browser-side protection. Their absence doesn't automatically mean the site has an XSS or clickjacking vulnerability, but it's an area that would be worth improving.

**How I'd improve it:** I'd add suitable headers and test them against the site's existing integrations. For CSP in particular, I'd start with a policy that works with Next.js scripts, analytics, and Cashfree checkout, then tighten it after testing rather than applying a policy that breaks the site.

You can see [next.config.example.mjs](examples/next.config.example.mjs) for a proposed config

## 3. One additional security observation

A public JavaScript file identifies a **Next.js 15.5.18** client build, and the site uses App Router and Server Actions that i Found with REA. That version falls within the affected ranges described in two Next.js security advisories: [GHSA-m99w-x7hq-7vfj](https://github.com/vercel/next.js/security/advisories/GHSA-m99w-x7hq-7vfj) and [GHSA-p3m5-59mp-jv5r](https://github.com/vercel/next.js/security/advisories/GHSA-p3m5-59mp-jv5r) 

I'd recommend checking the actual deployed server dependencies and updating to a supported patched version if needed.

## 4. Limitations and conclusion

Most of this audit came from public pages, static JavaScript, and HTTP headers. I didn't inspect private server code, database queries, authentication rules, or Cashfree's settlement records. A later manual checkout interaction created a production order, but no payment was completed or verified through that interaction. No order identifiers or tokens are included here.

The main improvements I'd suggest are better recovery from failed requests, clearer payment states, caching for suitable public pages, and stronger browser security headers. These are practical areas a backend team could review and test in its own development or staging environment.

That is it from my side, Thankyou for reading it!