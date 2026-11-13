<#
.SYNOPSIS
  Installs the skill packs in this repo into Claude Code, all at once or one by one.

.EXAMPLE
  .\install.ps1                               # everything
  .\install.ps1 -Only replica-skill,instagram-agent
  .\install.ps1 -Method link                  # link the submodule clones instead of using the plugin system
  .\install.ps1 -List

  Without cloning, from any PowerShell window:
  irm https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.ps1 | iex
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/aniketsharma04/claude-skills/main/install.ps1))) -Only replica-skill
#>
param(
  [string[]]$Only,
  [ValidateSet('plugin', 'link')][string]$Method = 'plugin',
  [switch]$List
)
$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Marketplace = 'claude-skills'
# GitHub repo that hosts the marketplace; used when this script runs without a clone (irm ... | iex).
$Repo = 'aniketsharma04/claude-skills'
$IsClone = $Root -and (Test-Path (Join-Path $Root '.claude-plugin/marketplace.json'))
$Source = if ($IsClone) { $Root } else { $Repo }

# name -> submodule path (used by -Method link)
$Packs = [ordered]@{
  'marketing-skills' = 'marketing/marketingskills'
  'instagram-agent'  = 'instagram/instagram-agent-skill'
  'linkedin-skills'  = 'linkedin/linkedin-skills'
  'replica-skill'    = 'replica-skill/replica-skill'
  'superpowers'      = 'superpowers/superpowers'
  'remotion'         = $null
  'rea'              = 'reverse-engineer/rea'
  'graphify'         = 'graphify/graphify'
}

# Packs installed by their own CLI instead of the marketplace or a junction.
$CliPacks = @('rea', 'graphify')

if ($List) { $Packs.Keys | ForEach-Object { "  $_" }; return }

$Selected = if ($Only) { $Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } } else { @($Packs.Keys) }
foreach ($name in $Selected) {
  if (-not $Packs.Contains($name)) { throw "Unknown pack '$name'. Run .\install.ps1 -List" }
}

function Need($cmd, $hint) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { throw "'$cmd' not found. $hint" }
}

# Some packs have paths past Windows' 260-char limit; allow long paths for git calls made by this script.
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.longpaths'
$env:GIT_CONFIG_VALUE_0 = 'true'

$Failed = @()

$ConfigDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$SkillsDir = Join-Path $ConfigDir 'skills'

function Install-Rea {
  Need npm 'Install Node.js 22.19 or newer from https://nodejs.org'
  Write-Host '==> rea: npm install -g rea-agents'
  npm install -g rea-agents
  rea setup --client claude_code --yes
  Write-Host '    rea: decompiling .exe/.dll needs Ghidra, APKs need JADX. See reverse-engineer/SETUP.md.'
}

function Install-Graphify {
  Need python 'Install Python 3.10 or newer from https://www.python.org'
  if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host '==> graphify: pip install --user uv'
    python -m pip install --user --quiet uv
  }
  Write-Host '==> graphify: uv tool install graphifyy'
  python -m uv tool install graphifyy
  $env:PATH = (Join-Path $HOME '.local/bin') + [IO.Path]::PathSeparator + $env:PATH
  graphify install
  if ($LASTEXITCODE -ne 0) { $script:Failed += 'graphify' }
  Write-Host '    graphify: run "python -m uv tool update-shell" once so the graphify command is on PATH. See graphify/SETUP.md.'
}

if ($Method -eq 'plugin') {
  Need claude 'Install Claude Code first: https://claude.com/claude-code'
  $pluginPacks = @($Selected | Where-Object { $CliPacks -notcontains $_ })
  if ($pluginPacks) {
    Write-Host "==> adding marketplace '$Marketplace' from $Source"
    claude plugin marketplace add $Source
    if ($LASTEXITCODE -ne 0) { claude plugin marketplace update $Marketplace }
    foreach ($name in $pluginPacks) {
      Write-Host "==> $name"
      claude plugin install "$name@$Marketplace"
      if ($LASTEXITCODE -ne 0) { $Failed += $name }
    }
  }
} else {
  Need git 'Install Git from https://git-scm.com'
  if (-not $IsClone) { throw "-Method link needs a clone: git clone https://github.com/$Repo.git" }
  New-Item -ItemType Directory -Force $SkillsDir | Out-Null
  foreach ($name in $Selected) {
    $path = $Packs[$name]
    if ($CliPacks -contains $name) { continue }
    if (-not $path) { Write-Host "==> $name has no submodule; install it with -Method plugin"; continue }
    # Its plugin.json points skills at the repo root, which loads none when linked; the marketplace entry lists them.
    if ($name -eq 'replica-skill') { Write-Host "==> $name loads no skills as a link; install it with -Method plugin"; continue }
    Write-Host "==> $name"
    git -C $Root submodule update --init $path
    $target = Join-Path $Root $path
    $link = Join-Path $SkillsDir (Split-Path $path -Leaf)
    if (Test-Path $link) { Write-Host "    already present: $link"; continue }
    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Host "    linked $link -> $target"
  }
}

if ($Selected -contains 'rea') { Install-Rea }
if ($Selected -contains 'graphify') { Install-Graphify }
if ($Selected -contains 'linkedin-skills') {
  Write-Host '    linkedin-skills: publishing needs Python deps and a .env. See its README (pip install -r requirements.txt, copy .env.example).'
}
if ($Failed) {
  Write-Host "Failed: $($Failed -join ', '). Fix the error above and re-run with -Only $($Failed -join ',')"
  exit 1
}
Write-Host 'Done. Restart Claude Code to load the new skills.'
