# Repository Security

The repo is public because Space Apps requires it. Public means anyone can **read** and **fork** it. Only collaborators can **push** or **merge**. An outsider can open a pull request from a fork, but only a collaborator can merge it. The settings below add further guard rails on top.

Repo: https://github.com/arslan-ahm/skylens---nasa-app-2026

## What protects the repo

| Protection | Where | Effect |
|---|---|---|
| Collaborators only | Settings → Collaborators | Only invited people can push. Give teammates **Write**, never Admin |
| Ruleset "Protect main" | `.github/rulesets/protect-main.json` | `main` changes only via pull request with green CI. No force-push, no deletion. Admins can bypass in an emergency |
| Ruleset "Protect pre-event baseline tag" | `.github/rulesets/protect-baseline-tag.json` | Only an admin can move or delete `pre-event-*` tags (needed at the Nov 13 freeze) |
| Fork PRs can't touch secrets | `ci.yml` + Actions setting below | Workflow token is read-only. APK and deploy jobs only run on `main`. Fork PRs need approval before CI runs |
| CODEOWNERS | `.github/CODEOWNERS` | Every PR is routed to the repo owner |
| Private vulnerability reports | `SECURITY.md` + setting below | Security issues are reported privately, not as public issues |
| Secret scanning + push protection | Setting below | GitHub blocks pushes that contain API keys |

## One-time setup (owner, about 5 minutes)

All of these are under https://github.com/arslan-ahm/skylens---nasa-app-2026/settings

1. **Rules → Rulesets → New ruleset → Import a ruleset.** Import `.github/rulesets/protect-main.json`, then click **Create**. Repeat for `protect-baseline-tag.json`. Download them from the repo, or pick them from your local clone.
2. **Actions → General:**
   - *Fork pull request workflows from outside collaborators*: **Require approval for all external contributors**.
   - *Workflow permissions*: **Read repository contents and packages permissions**. Leave "Allow GitHub Actions to create and approve pull requests" **unticked**.
3. **Advanced Security** (named "Code security" on some accounts):
   - Enable **Private vulnerability reporting**.
   - Enable **Dependabot alerts**.
   - Enable **Secret scanning** and **Push protection**.
4. **General → Pull Requests:** tick **Automatically delete head branches**. Optionally allow squash merging only.
5. **Pages → Source: GitHub Actions** (deploys the web build).
6. **Collaborators → Add people:** add teammates with the **Write** role.

## Team workflow under these rules

```bash
git switch -c feat/tonight-view     # branch per change
git push -u origin feat/tonight-view
# open a PR on GitHub, wait for the green "Analyze, test, build web" check, then merge
```

No approval is required (`required_approving_review_count: 0`), so a teammate can merge their own PR once CI is green. That keeps the 48 hours fast. For stricter review, set it to `1` in the ruleset.

## Never

- Never commit `app/.env.json` or any key. Push protection is a backstop, not the plan.
- Never give a teammate the Admin role, and never disable the rulesets during the event.
- Never add repository secrets that pull-request workflows can read.
