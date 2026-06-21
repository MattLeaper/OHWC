# Admin (Decap CMS) setup

This folder contains the Decap CMS admin UI (`index.html`) and the CMS config (`config.yml`).

Quick checklist to get the admin working:

1. Repo config
   - In `config.yml` set `repo: owner/repo` (already set to `MattLeaper/OHWC`).

2. Choose an auth method
   - Option A (GitHub OAuth): create a GitHub OAuth App and set the Authorization callback URL to `https://<your-site>/admin/` (or `http://localhost:8080/admin/` for local testing). Use the OAuth Client ID when prompted by your hosting provider or pass it as a query param: `/admin/?auth_client_id=YOUR_ID`.
   - Option B (Git Gateway + Netlify Identity): easier if you host on Netlify. Enable Netlify Identity and Git Gateway and use `backend: git-gateway` in `config.yml`.

3. Host the `admin/` folder
   - Deploy to your site so the admin UI is available at `https://<your-site>/admin/` (Decap CMS expects `config.yml` at `/admin/config.yml`).

4. Local testing (quick)
   - Start a simple static server from the repository root and open `/admin/` in the browser. Example using Python:

```powershell
# from repository root
python -m http.server 8080
# then open http://localhost:8080/admin/
```

or using `npx`:

```powershell
npx http-server -p 8080
```

Notes and troubleshooting
- If the browser shows a login page but you can't authenticate, double-check your GitHub OAuth app's callback URL.
- If PDF/image/file uploads fail, ensure the folder specified in `media_folder` exists in the repo (e.g. `images/uploads`).
- If you prefer, I can switch `config.yml` to `backend: git-gateway` and show the Netlify steps.

If you want, I can:
- Create a GitHub OAuth App example step-by-step.
- Switch `config.yml` to `git-gateway` and provide Netlify setup instructions.
- Try a local test run and report any errors.

Netlify setup (git-gateway + Identity)

1. Deploy the site to Netlify
   - Connect your GitHub repo to Netlify and deploy the site.

2. Enable Netlify Identity
   - In Netlify dashboard, open your site → "Identity" → click "Enable Identity".

3. Enable Git Gateway
   - In the Identity panel, open "Services" (or the "Git Gateway" section) and enable Git Gateway.
   - Give Netlify permission to access the repository when prompted.

4. Invite admin users
   - In Identity → "Invite users", invite the account(s) that will log into the admin.
   - Alternatively, enable registration (not recommended for public sites).

5. Open the admin UI
   - Visit `https://<your-site>/admin/` and login with the Netlify Identity account you invited.
   - Once logged in, the CMS will use Git Gateway to commit changes to your repo.

Optional: local testing with Netlify CLI

- Install Netlify CLI: `npm install -g netlify-cli`
- Link your local folder to the Netlify site: `netlify link` (choose the site you created).
- Run `netlify dev` — this starts a local dev server and proxies Identity/Gateway for admin testing.

Troubleshooting

- If you get an "Authentication failed" error, ensure Git Gateway is enabled and the site has permission to access the repo.
- If uploads fail, ensure the `media_folder` path exists in the repo and that the authenticated Netlify user has commit rights.
- If you want me to set `config.yml` back to the GitHub backend after you finish Netlify setup, I can do that.
