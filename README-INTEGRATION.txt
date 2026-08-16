OHWC coach sign-up — integration notes
=======================================

What's in this folder
----------------------
- coach_signup.html      NEW page: the members' coach booking tool, using your
                          site's real header/nav/footer and styles.css.
- index.html
- Monthly_walks.html
- membership.html
- news.html
- walk_info.html
- club_info.html
- safeguarding.html
- gallery.html            Your existing pages, each with one new nav link added:
                          "Book Coach" -> coach_signup.html
- styles.css              Unchanged from your current site (included for completeness).
- CNAME                   Unchanged.

How to use this
----------------
1. In your GitHub repo, replace the 8 existing HTML pages with the versions
   here (they are identical to your current pages except for the one added
   nav link each).
2. Add coach_signup.html to the repo root (same level as index.html).
3. Do NOT copy the images/ or documents/ folders from here — they don't
   exist in this package. Keep your existing images/ and documents/ folders
   exactly as they are; coach_signup.html doesn't need any new images.
4. Commit and push (or use Decap CMS / your normal deploy process) — Netlify
   will rebuild and the new page + nav link will go live.

About this tool
----------------
This is a working PROTOTYPE, not a production system:
- Login is just "type a name" (member) or "type a shared passcode"
  (committee) — not real per-person authentication.
- The 12-person walk cap is enforced in the browser, not on a server, so a
  determined person could bypass it with browser dev tools.
- Data is stored in Claude's artifact storage, tied to this specific file —
  it is NOT connected to your real membership list, and won't survive a
  redesign of this page.

Treat it as something to show the committee "here's roughly what this could
look like and how it would feel to use" before commissioning (or building)
the real, database-backed version discussed alongside this file.
