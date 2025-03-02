FROM python:3.13-slim-bullseye

# Use Docker's automatic build arg for architecture
ARG TARGETARCH

# Set environment variables for version numbers
ENV GITLEAKS_VERSION=8.24.0
ENV TRUFFLEHOG_VERSION=3.88.14
ENV TALISMAN_VERSION=1.32.0
ENV TALISMAN_HTML_REPORT_VERSION=1.3

# Install dependencies + pip tools
RUN apt-get update && \
    apt-get install -y git wget curl unzip procps bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install gittyleaks detect-secrets ggshield

# Gitleaks: choose arm64 or amd64
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz"; \
    else \
      GITLEAKS_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"; \
    fi && \
    echo "Downloading Gitleaks for $TARGETARCH: $GITLEAKS_URL" && \
    wget -O gitleaks.tar.gz "$GITLEAKS_URL" && \
    tar -xzf gitleaks.tar.gz -C /usr/local/bin/ && \
    rm gitleaks.tar.gz

# Trufflehog: choose arm64 or amd64
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      TRUFFLEHOG_URL="https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_arm64.tar.gz"; \
    else \
      TRUFFLEHOG_URL="https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz"; \
    fi && \
    echo "Downloading Trufflehog for $TARGETARCH: $TRUFFLEHOG_URL" && \
    wget -O trufflehog.tar.gz "$TRUFFLEHOG_URL" && \
    tar -xzf trufflehog.tar.gz -C /usr/local/bin/ && \
    rm trufflehog.tar.gz

# Talisman: choose arm64 or amd64
RUN if [ "${TARGETARCH}" = "arm64" ]; then \
      TALISMAN_URL="https://github.com/thoughtworks/talisman/releases/download/v${TALISMAN_VERSION}/talisman_linux_arm64"; \
    else \
      TALISMAN_URL="https://github.com/thoughtworks/talisman/releases/download/v${TALISMAN_VERSION}/talisman_linux_amd64"; \
    fi && \
    echo "Downloading Talisman for $TARGETARCH: $TALISMAN_URL" && \
    wget -O /usr/local/bin/talisman "$TALISMAN_URL" && \
    chmod +x /usr/local/bin/talisman

RUN mkdir -p /root/.talisman && \
    curl https://github.com/jaydeepc/talisman-html-report/archive/v${TALISMAN_HTML_REPORT_VERSION}.zip -o /root/.talisman/talisman_html_report.zip -J -L && \
    cd /root/.talisman && \
    unzip talisman_html_report.zip -d . && \
    mv talisman-html-report-1.3 talisman_html_report && \
    rm talisman_html_report.zip

# Set environment variables
ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=true

# api key of git guaridan here, if you have. instead of abcd put that value
ENV GGSHIELD_TOKEN=abcd
RUN echo "$GGSHIELD_TOKEN" | ggshield auth login --method token 2>&1 || \
    echo "ggshield login failed or token not provided. Continuing without authentication."

# Prepare the workspace
WORKDIR /app

# Download banner and rainbow script from GitHub
RUN wget -O /app/banner.txt "https://raw.githubusercontent.com/KaustubhRai/rahasya/main/Secret%20Scanning/src/rainbow-scripts/banner.txt" && \
    wget -O /usr/local/bin/rainbow.py "https://raw.githubusercontent.com/KaustubhRai/rahasya/main/Secret%20Scanning/src/rainbow-scripts/rainbow.py" && \
    chmod +x /usr/local/bin/rainbow.py

# Embed a Python script for cleaning the gittyleaks report
RUN echo 'import re\n\
import sys\n\
\n\
def remove_ansi_escape_codes(file_path):\n\
    ansi_escape = re.compile(r"\x1B\[\d+(;\d+)*m")\n\
    with open(file_path, "r") as file:\n\
        content = file.read()\n\
    cleaned_content = ansi_escape.sub("", content)\n\
    with open(file_path, "w") as file:\n\
        file.write(cleaned_content)\n\
\n\
if __name__ == "__main__":\n\
    remove_ansi_escape_codes(sys.argv[1])' > /usr/local/bin/clean_gittyleaks_report.py && \
    chmod +x /usr/local/bin/clean_gittyleaks_report.py

# Create trufflehog_exclude.txt with exclude patterns
RUN echo -e "Secret_Detection_Reports/\ntalisman_html_report/" > /trufflehog_exclude.txt

# Script to handle user input and execute tools accordingly
RUN { \
    echo '#!/bin/bash'; \
    echo 'python3 /usr/local/bin/rainbow.py /app/banner.txt'; \
    echo 'printf "\\n\033[1mFeatures Available:\\033[0m\\n"'; \
    echo 'printf "%s\\n" "- GitLeaks (https://github.com/gitleaks/gitleaks)"'; \
    echo 'printf "%s\\n" "- Gitty Leaks (https://github.com/kootenpv/gittyleaks)"'; \
    echo 'printf "%s\\n" "- TruffleHog (https://github.com/trufflesecurity/trufflehog)"'; \
    echo 'printf "%s\\n" "- Detect Secrets (https://github.com/Yelp/detect-secrets)"'; \
    echo 'printf "%s\\n" "- Git Guardian (Requires API Key). (https://github.com/GitGuardian/ggshield)"'; \
    echo 'printf "%s\\n" "- Talisman (https://github.com/thoughtworks/talisman)"'; \
    echo 'printf "\\n%s\\n" "✨ GIT CLONE THE REPO, TOOLS WILL WORK AT FULL POTENTIAL ONLY THEN. DONT KNOW HOW? USE, -help"'; \
    echo 'printf "\\n\033[1mUsage:\\033[0m\\n"'; \
    echo 'printf "%s\\n" "  \033[1;32m-scan\033[0m                 Scan the repo using all tools excluding Talisman"'; \
    echo 'printf "%s\\n" "  \033[1;32m-include_talisman\033[0m     Scan the repo with Talisman"'; \
    echo 'printf "%s\\n" "  \033[1;32m-scan [tool1] [tool2]\033[0m Scan the repo with specified tools (gitleaks, gittyleaks, trufflehog, detect-secrets, ggshield)"'; \
    echo 'printf "%s\\n" "  \033[1;32m-help\033[0m                 Show help for git clone"'; \
    echo 'printf "\\n"'; \
    echo 'read -p "\033[1mEnter the flags you want to use:\033[0m " cmd'; \
    echo 'printf "\\n"'; \
    echo 'TOOLS=()'; \
    echo 'if [ "$cmd" = "-include_talisman" ]; then'; \
    echo '  TOOLS=("talisman")'; \
    echo 'elif [ "$cmd" = "-scan" ]; then'; \
    echo '  TOOLS=("gitleaks" "gittyleaks" "trufflehog" "detect-secrets" "ggshield")'; \
    echo 'elif echo $cmd | grep -q "^-scan "; then'; \
    echo '  cmd=$(echo $cmd | sed "s/-scan //")'; \
    echo '  IFS=" " read -r -a TOOLS <<< "$cmd"'; \
    echo 'elif [ "$cmd" = "-help" ]; then'; \
    echo '  printf "\\n\033[1mGit Clone Help:\033[0m\\n"'; \
    echo '  printf "  \033[1;34mgit clone <repo_url>\033[0m\\n"'; \
    echo '  printf "  \033[1;34mgit clone --single-branch --branch <branch name> <repo_url>\033[0m\\n\\n"'; \
    echo '  printf "\\n\033[1mExamples using -scan flag:\033[0m\\n"'; \
    echo '  printf "  \033[1;34m-scan\033[0m\t\t\t\t\tScan the repository using all tools excluding Talisman.\\n"'; \
    echo '  printf "  \033[1;34m-scan gitleaks\033[0m\t\t\tScan the repository using a single tool.\\n"'; \
    echo '  printf "  \033[1;34m-scan trufflehog gittyleaks ggshield\033[0m\tScan the repository using multiple tools.\\n"'; \
    echo '  printf "  \033[0;32mTools can be specified in any order.\\n\\n"'; \
    echo '  exit 0'; \
    echo 'else'; \
    echo '  echo "Invalid flag. Please use \033[1;32m-scan\033[0m, \033[1;32m-include_talisman\033[0m, \033[1;32m-scan [tool1] [tool2] ...\033[0m, or \033[1;32m-help\033[0m."'; \
    echo '  exit 1'; \
    echo 'fi'; \
    echo 'if [ ! -d "/repo/.git" ] && [ "${#TOOLS[@]}" > 0 ]; then'; \
    echo '  printf "\\033[0;31mError: Git repository not found in /repo\\033[0m\\n"'; \
    echo '  exit 1'; \
    echo 'fi'; \
    echo 'cd /repo || exit'; \
    echo 'mkdir -p /repo/Secret_Detection_Reports'; \
    echo 'for tool in "${TOOLS[@]}"; do'; \
    echo '  case "$tool" in'; \
    echo '    "gitleaks")'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;36mStarting GitLeaks...\\033[0m\\n"'; \
    echo '    gitleaks detect --source=. --gitleaks-ignore-path='Secret_Detection_Reports/*' --gitleaks-ignore-path='talisman_html_report/*' --report-format=json --report-path=/repo/Secret_Detection_Reports/gitleaks_report.json --verbose'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;32mGitleaks scan complete.\\033[0m\\n"'; \
    echo 'printf "\\n"'; \
    echo '      ;;'; \
    echo '    "gittyleaks")'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;36mStarting GittyLeaks...\\033[0m\\n"'; \
    echo '    gittyleaks --find-anything | tee /repo/Secret_Detection_Reports/gittyleaks_report.txt'; \
    echo '    python /usr/local/bin/clean_gittyleaks_report.py /repo/Secret_Detection_Reports/gittyleaks_report.txt'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;32mGittyLeaks scan complete.\\033[0m\\n"'; \
    echo 'printf "\\n"'; \
    echo '      ;;'; \
    echo '    "trufflehog")'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;36mStarting TruffleHog...\\033[0m\\n"'; \
    echo '    /usr/local/bin/trufflehog --no-update git file:///repo --exclude-paths=/trufflehog_exclude.txt >> /repo/Secret_Detection_Reports/trufflehog_report.txt'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;32mTruffleHog scan complete.\\033[0m\\n"'; \
    echo 'printf "\\n"'; \
    echo '      ;;'; \
    echo '    "detect-secrets")'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;36mStarting Detect-secrets...\\033[0m\\n"'; \
    echo '    detect-secrets scan --all-files --exclude-files '^Secret_Detection_Reports/' --exclude-files '^talisman_html_report/' >> /repo/Secret_Detection_Reports/Detect_Secrets-Report.txt'; \
    echo 'printf "\\n"'; \
    echo '      printf "\\033[0;32mDetect-Secrets scan complete.\\033[0m\\n"'; \
    echo 'printf "\\n"'; \
    echo '      ;;'; \
    echo '    "ggshield")'; \
    echo 'printf "\\n"'; \
    echo '    printf "\\033[0;36mStarting GitGuardian...\\033[0m\\n"'; \
    echo '    ggshield api-status > /tmp/ggshield_api_status.txt'; \
    echo '    if grep -q "Status: healthy" /tmp/ggshield_api_status.txt; then'; \
    echo '      ggshield_quota=$(ggshield quota | grep "Quota available:" | awk "{print \$3}")'; \
    echo '      if [ "$ggshield_quota" -le 500]; then'; \
    echo '        printf "\\033[0;33mQuota not available, exiting Git Guardian. Wait next month to refill quota 🤷\\033[0m\\n"'; \
    echo '      else'; \
    echo '        printf "\\033[0;36mRunning GitGuardian scan...\\033[0m\\n"'; \
    echo '        ggshield secret scan --show-secrets repo . >> /repo/Secret_Detection_Reports/ggshield_report.txt'; \
    echo 'printf "\\n"'; \
    echo '        printf "\\033[0;32mGit Guardian scan complete.\\033[0m\\n"'; \
    echo '      fi'; \
    echo '    else'; \
    echo '      printf "\\033[0;33mSkipping Git Guardian Scan since API key is not present\\033[0m\\n"'; \
    echo '    fi'; \
    echo 'printf "\\n"'; \
    echo '      ;;'; \
    echo '    "talisman")'; \
    echo 'printf "\\n"'; \
    echo '    printf "\\033[0;36mStarting Talisman...\\033[0m\\n"'; \
    echo '    if [ ! -d "/repo/.git" ]; then'; \
    echo '      printf "\\033[0;31mError: Git repository not found in /repo\\033[0m\\n"'; \
    echo '      exit 1'; \
    echo '    fi'; \
    echo '    talisman --scanWithHtml --reportDirectory=/repo/Secret_Detection_Reports'; \
    echo '    if [ -d "/repo/talisman_html_report" ]; then'; \
    echo '      printf "\\n\\033[0;33mTo view the Talisman HTML report, run the following command:\\033[0m\\n"'; \
    echo '      printf "\\033[1;92mcd talisman_html_report/ && python3 -m http.server 8000\\033[0m\\n"'; \
    echo '      printf "\\033[0;33mThen, visit: http://localhost:8000 in your browser.\\033[0m\\n"'; \
    echo '    else'; \
    echo '      printf "\\033[0;31mTalisman HTML report directory not found\\033[0m\\n"'; \
    echo '    fi'; \
    echo '      ;;'; \
    echo '    *)'; \
    echo '      echo "Invalid tool: $tool. Skipping...";'; \
    echo '      ;;'; \
    echo '  esac'; \
    echo 'done'; \
} > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Set the entrypoint to run the script
ENTRYPOINT ["/app/entrypoint.sh"]
