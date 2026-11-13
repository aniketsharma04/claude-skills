# Claude Skills

A curated set of free Claude Code skill packs, installable in one go or one by one.
Every pack is someone else's open-source project, included here as a git submodule pinned to a tested
version. This repo adds one marketplace file and an installer on top. No paid APIs needed to get started.

| Pack | Skills | What it does | Upstream (license) |
| --- | --- | --- | --- |
| `marketing-skills` | 50 | CRO, copywriting, SEO, AI SEO, ads, emails, launch, pricing, ... | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) (MIT) |
| `instagram-agent` | 13 | Reels, carousels, captions, comments, DMs, viral research, humanizer | [Jakeschincariol/instagram-agent-skill](https://github.com/Jakeschincariol/instagram-agent-skill) (MIT) |
| `linkedin-skills` | 12 | Post writer, comment and reply drafting, hook extractor, profile optimizer | [sergebulaev/linkedin-skills](https://github.com/sergebulaev/linkedin-skills) (MIT) |
| `replica-skill` | 11 | Clone an app clean-room style: recon, build, test, diff, review mining, launch | [Jakeschincariol/replica-skill](https://github.com/Jakeschincariol/replica-skill) (MIT) |
| `superpowers` | 15 | Dev workflow: brainstorm, write plans, TDD, systematic debugging, code review, worktrees | [obra/superpowers](https://github.com/obra/superpowers) (MIT) |
| `remotion` | 12 | Make videos in React with Remotion | [remotion-dev/skills](https://github.com/remotion-dev/skills) |
| `rea` | 1 + MCP server | Reverse engineer binaries, APKs, Electron apps, web bundles | [morluto/rea](https://github.com/morluto/rea) (MIT) |
| `graphify` | 1 + CLI | Turn a codebase, docs, PDFs or media into a queryable knowledge graph (`/graphify .`) | [Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (Apache-2.0) |

## Requirements

- [Claude Code](https://claude.com/claude-code) and Git
- Node.js 22.19+ (only for `rea`)
- Python 3.8+ (some packs ship small Python tools; 3.10+ for `graphify`)

No cloning needed for any of the options below: Claude Code pulls each pack straight from GitHub.
Restart Claude Code after installing.

## Option 1: everything in one go (one command)

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.ps1 | iex
```

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.sh | bash
```

The installer adds this repo as a plugin marketplace, installs every pack as a plugin, installs `rea`
through npm and `graphify` through uv (Python). If one pack fails, it keeps going and tells you what to re-run.
(Prefer to read a script before running it? Open the URL above first, or download it and run it.)

Only some packs, still one command:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.ps1))) -Only replica-skill,instagram-agent
```

```bash
curl -fsSL https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.sh | bash -s -- --only replica-skill,instagram-agent
```

## Option 2: one by one in the terminal (no script)

Add the marketplace once, then install the packs you want:

```bash
claude plugin marketplace add aniketsharma04/claude-skills

claude plugin install marketing-skills@claude-skills
claude plugin install instagram-agent@claude-skills
claude plugin install linkedin-skills@claude-skills
claude plugin install replica-skill@claude-skills
claude plugin install superpowers@claude-skills
claude plugin install remotion@claude-skills

npm install -g rea-agents && rea setup --client claude_code --yes    # rea is not a plugin
uv tool install graphifyy && graphify install                          # graphify is not a plugin
```

The same works inside Claude Code as `/plugin marketplace add aniketsharma04/claude-skills` and
`/plugin install replica-skill@claude-skills`. `/plugin` on its own opens a picker.

To update later: `claude plugin marketplace update claude-skills`, then `claude plugin update <pack>@claude-skills`.

## Option 3: straight from each pack's own repo

Each pack also installs straight from its own repo, without this one:

| Pack | Command in Claude Code |
| --- | --- |
| marketing-skills | `/plugin marketplace add coreyhaines31/marketingskills` then `/plugin install marketing-skills@marketingskills` |
| instagram-agent | `/plugin marketplace add Jakeschincariol/instagram-agent-skill` then `/plugin install instagram-agent@instagram-agent-skill` |
| linkedin-skills | `/plugin marketplace add sergebulaev/linkedin-skills` then `/plugin install linkedin-skills@linkedin-skills` |
| replica-skill | `/plugin marketplace add Jakeschincariol/replica-skill` then `/plugin install replica-skill@replica-skill` |
| superpowers | `/plugin install superpowers@claude-plugins-official` (in Anthropic's official marketplace) |
| remotion | `npx skills add remotion-dev/skills` (in a terminal) |
| rea | `npm install -g rea-agents` then `rea setup --client claude_code --yes` |
| graphify | `uv tool install graphifyy` (or `pipx install graphifyy`) then `graphify install` (in a terminal) |

## Option 4: clone and link (to edit the skills)

If you want to edit the skills or pin the exact versions in this repo, link the submodules into your skills
folder instead of using the plugin system:

```powershell
git clone https://github.com/aniketsharma04/claude-skills.git claude-skills
cd claude-skills
.\install.ps1 -Method link                 # Windows: creates junctions
./install.sh --method link                 # macOS / Linux: creates symlinks
```

The installer fetches just the submodules you pick. Avoid `--recurse-submodules`: REA's own nested test
submodule has filenames Windows cannot create, and you never need its source (REA installs through npm).

To update later: `git pull && git submodule update --remote`.

## After installing

- Skills show up namespaced by pack, e.g. `/replica-skill:replica-recon`, `/instagram-agent:ig-reel`.
- `linkedin-skills` publishing needs its Python deps and a `.env` (copy `.env.example`); see its README.
- `rea` decompiling `.exe`/`.dll` needs [Ghidra](https://ghidra-sre.org); APKs need JADX. See
  [reverse-engineer/SETUP.md](reverse-engineer/SETUP.md).
- `graphify` installs a `graphify` CLI into `~/.local/bin`; run `uv tool update-shell` once if the command is
  not found. See [graphify/SETUP.md](graphify/SETUP.md).
- Windows: if git reports "Filename too long" outside the installer, run `git config --global core.longpaths true`.

## Layout

```
.claude-plugin/marketplace.json     the marketplace that lists every pack
install.ps1, install.sh             the one-go installer
marketing/marketingskills           submodule
instagram/instagram-agent-skill     submodule
linkedin/linkedin-skills            submodule
replica-skill/replica-skill         submodule (+ SETUP.md)
reverse-engineer/rea                submodule (+ SETUP.md)
superpowers/superpowers             submodule
graphify/graphify                   submodule (+ SETUP.md)
```

## Credits and license

All skill packs belong to their authors and keep their own licenses (see each submodule). The files in this repo
itself (marketplace, installers, README) are MIT, see [LICENSE](LICENSE).
