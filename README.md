# A Comprehensive Secret Scanning Automation-Tool

![Docker Image Version (tag)](https://img.shields.io/docker/v/raikaustubh/rahasya/latest?logo=docker)


Securing your codebase with various tools for secret scanning

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Flags](#flags)
- [Customization](#customization)
- [Requirements](#requirements)
- [Contribution Guidelines](#contribution-guidelines)
- [License](#license)
- [Troubleshooting](#troubleshooting)
- [FAQs](#faqs)
- [Credits](#credits)

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
<img width="1111" alt="image" src="https://github.com/KaustubhRai/rahasya/assets/28558847/f7728a0b-c3e6-447a-a284-a80cc9e88e5a">

## Flags

- `-scan`: Run GitLeaks, Gitty Leaks, TruffleHog, Detect Secrets all in succession one after the other, and Git Guardian too, if you have the API Key available in the dockerfile.

- `-include_talisman`: Run Talisman separately from all the other tools. This flag will run Talisman and format that report in a presentable format that can be viewed in the browser.

- `-help`: All the tools will only run properly if the repo is git cloned. Use this flag if you need guidance on how to proceed.

- `-scan [tool 1] [tool 2] ...`: Selectively run specified scanning tools. List the tools you want to execute, separated by spaces. Supported tools include `gitleaks`, `gittyleaks`, `trufflehog`, `detect-secrets`, and `gggshield`. If `gitguardian` or `gggshield` is specified, ensure you have provided the API key in the Dockerfile. Use this flag to customize the scan to your specific needs. For example, to run GitLeaks and TruffleHog, use `-scan gitleaks trufflehog`.

## Customization

To incorporate your Git Guardian API key or to modify any tool versions:

1. **Clone the repository:**
```bash
   git clone https://github.com/KaustubhRai/rahasya.git
```
2. **Edit the Dockerfile:**
   Add your API key in `ENV GGSHIELD_TOKEN` or adjust the tool versions as necessary.
3. **Build your custom Docker image:**
   ```bash
   docker build -t rahasya .
   ```
4. **Run that modified image:**
   ```bash
   docker run -it --rm -v "$(PWD):/repo" rahasya
   ```
## Requirements

 - Docker version 4.20.1 or higher
 - Compatible with Linux, macOS, Windows

## Contribution Guidelines
Contributions are welcome! Please submit a pull request or open an issue to discuss proposed changes.

## License
This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the LICENSE.md file for details.

## Troubleshooting
If you encounter issues with Docker permissions, ensure your user is added to the Docker group or try running with `sudo`.

## FAQs
> **Q: Can I use this tool without Docker?**
>
> **A:** Currently, Docker is required for running this tool efficiently.

## Credits
Developed by Kaustubh Rai. Thanks to all the developers of the tools integrated into this project.
