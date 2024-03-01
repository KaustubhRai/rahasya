# Automation-Tool for Secret Scanning

Various tools for secret scanning combined for different different stuff, used in day to day tasks

## Features
- GitLeaks (https://github.com/gitleaks/gitleaks)
- Gitty Leaks (https://github.com/kootenpv/gittyleaks)
- TruffleHog (https://github.com/trufflesecurity/trufflehog)
- Detect Secrets (https://github.com/Yelp/detect-secrets)
- Git Guardian (Requires API Key). (https://github.com/GitGuardian/ggshield)
- Talisman (https://github.com/thoughtworks/talisman)


## Installation

```
docker pull raikaustubh/rahasya
```

## Usage


```
docker run -it --rm -v "$(PWD):/repo" raikaustubh/rahasya
```
<img width="1250" alt="image" src="https://github.com/KaustubhRai/rahasya/assets/28558847/85c03d98-b110-4975-90d3-9454be628503">

## Flags

- `-scan`: Run GitLeaks, Gitty Leaks, TruffleHog, Detect Secrets all in succession one after the other, and Git Guardian too, if you have the API Key available in the dockerfile.

- `-include_talisman`: Run Talisman separately from all the other tools. This flag will run Talisman and format that report in a presentable format that can be viewed in the browser.

- `-help`: All the tools will only run properly if the repo is git cloned. Use this flag if you need guidance on how to proceed.
