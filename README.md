# Cynbit Backend Technical Assessment

This repo contains my technical review of Cynbit's website for the Backend Developer Intern assessment.

I reviewed the publicly accessible pages and JavaScript files to understand how the website handles requests, form submissions, payments, and other backend-related operations

My main focus was to identify areas where error handling, security, or performance could be improved and explain how I would approach those improvements as a backend developer.

## What I Found

During the review, I focused on four areas:

**1. Form Submission and Error Handling**

I noticed that the contact form might not reset its loading state properly if a server request fails unexpectedly. I suggested handling these errors using `try/catch/finally` so users can retry without getting stuck.

**2. Payment Verification**

While reviewing the BitElevate payment flow, I found that some unsuccessful verification responses display a message saying the customer wasn't charged.

Since an unsuccessful verification doesn't always mean the payment failed, I suggested handling pending payments separately and confirming the final status with the payment provider. I have also included an example of how idempotency can help prevent duplicate processing.

**3. Caching and Performance**

I noticed that several publicly accessible pages, including blogs and career listings, were being served without shared HTML caching.

I suggested using caching with revalidation for suitable public content to reduce unnecessary server work, while keeping user-specific and payment-related responses private.

**4. Security Improvements**

Some recommended HTTP security headers were missing from the pages I inspected.

I suggested adding appropriate headers and reviewing the Content Security Policy (CSP) to improve browser-side protection without affecting existing website functionality.

I also briefly reviewed the publicly visible Next.js version against known security advisories. This would need further verification from the backend team.

## Repository Contents

- [BACKEND-AUDIT.md](BACKEND-AUDIT.md): Detailed observations, the website's apparent architecture, API behavior, and suggested improvements.
- [examples/recovery.mjs](examples/recovery.mjs): Example of handling form submission errors and uncertain payment states.
- [examples/next.config.example.mjs](examples/next.config.example.mjs): Example Next.js security header configuration.
- [examples/payment-idempotency.sql](examples/payment-idempotency.sql): Example of using database constraints and transactions to help prevent duplicate payment processing.

## How I Reviewed the Website

I used Chrome DevTools, publicly available JavaScript bundles, HTTP response headers, and REA to understand the website's observable behavior.

The main audit was based on public information and static code analysis and I did not have access to Cynbit's backend source code or database, so those findings are potential improvements rather than confirmed backend issues obviously.

The code examples are my suggested approaches..

## Conclusion

Overall, I found a few areas worth reviewing, particularly around payment status handling, form errors, caching, and security configuration and my goal with this assessment was to understand the existing behavior from a backend developer's perspective and suggest practical improvements based on what i could observe.