# Use a base image with Python, git, and other necessary tools
FROM python:3.12-slim-bullseye

# Install necessary tools and dependencies
RUN apt-get update && \
    apt-get install -y git wget make curl unzip procps && \
    wget https://go.dev/dl/go1.21.2.linux-amd64.tar.gz && \
    tar -xvf go1.21.2.linux-amd64.tar.gz && \
    mv go /usr/local && \
    rm go1.21.2.linux-amd64.tar.gz

# Set environment variables
ENV PATH="$PATH:/usr/local/go/bin"
ENV GIT_DISCOVERY_ACROSS_FILESYSTEM=true

# Install gittyleaks and Gitleaks
RUN pip install gittyleaks && \
    wget -O /tmp/gitleaks.tar.gz https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz && \
    tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks && \
    chmod +x /usr/local/bin/gitleaks && \
    rm /tmp/gitleaks.tar.gz

# Download and install the TruffleHog binary
RUN wget -O /usr/local/bin/trufflehog https://github.com/trufflesecurity/trufflehog/releases/download/v3.67.0/trufflehog_3.67.0_linux_amd64.tar.gz && \
    tar -xzvf /usr/local/bin/trufflehog -C /usr/local/bin/ trufflehog && \
    chmod +x /usr/local/bin/trufflehog

# Install detect-secrets
RUN pip install detect-secrets

# Install Talisman
RUN wget -O /usr/local/bin/talisman https://github.com/thoughtworks/talisman/releases/download/v1.32.0/talisman_linux_amd64 && \
    chmod +x /usr/local/bin/talisman

# Install Talisman HTML Report
RUN mkdir -p /root/.talisman && \
    curl https://github.com/jaydeepc/talisman-html-report/archive/v1.3.zip -o /root/.talisman/talisman_html_report.zip -J -L && \
    cd /root/.talisman && \
    unzip talisman_html_report.zip -d . && \
    mv talisman-html-report-1.3 talisman_html_report && \
    rm talisman_html_report.zip

# Install ggshield
RUN pip install ggshield

# Automating ggshield auth login with hardcoded token
# provide the GG Shield api token here
ENV GGSHIELD_TOKEN=abcd
RUN echo "$GGSHIELD_TOKEN" | ggshield auth login --method token 2>&1 || \
    echo "ggshield login failed or token not provided. Continuing without authentication."


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

# Update the entrypoint script
RUN echo '#!/bin/bash\n\
\n\
# Ensure we are in the mounted Git repository directory\n\
if [ ! -d "/repo/.git" ]; then\n\
    echo -e "\033[0;31mError: Git repository not found in /repo\033[0m"\n\
    exit 1\n\
fi\n\
cd /repo\n\
\n\
mkdir -p /repo/Secret_Detection_Reports\n\
\n\
# Git Guardian scan\n\
ggshield api-status > /tmp/ggshield_api_status.txt\n\
if grep -q "Status: healthy" /tmp/ggshield_api_status.txt; then\n\
    # Proceed if API is healthy\n\
    ggshield_quota=$(ggshield quota | grep "Quota available:" | awk "{print \$3}")\n\
    if [ "$ggshield_quota" -le 500 ]; then\n\
        echo "\033[0;33mQuota not available, exiting Git Guardian. Wait next month to refill quota 🤷\033[0m"\n\
    else\n\
        ggshield secret scan --show-secrets repo . >> /repo/Secret_Detection_Reports/ggshield_report.txt\n\
        echo "\033[0;32mGit Guardian scan complete.\033[0m"\n\
    fi\n\
else\n\
    # Skipping GitGuardian scan since API Key is not available\n\
    echo "\033[0;33mSkipping Git Guardian Scan since API key is not present\033[0m"\n\
fi\n\
\n\
echo -e "\033[0;36m\n\nStarting GittyLeaks...\033[0m"\n\
gittyleaks --find-anything | tee /repo/Secret_Detection_Reports/gittyleaks_report.txt\n\
python /usr/local/bin/clean_gittyleaks_report.py /repo/Secret_Detection_Reports/gittyleaks_report.txt\n\
echo -e "\033[0;32mGittyleaks scan complete.\033[0m"\n\
\n\
echo -e "\033[0;36m\n\nStarting GitLeaks...\033[0m"\n\
gitleaks detect --source=. --gitleaks-ignore-path='Secret_Detection_Reports/*' --gitleaks-ignore-path='talisman_html_report/*' --report-format=json --report-path=/repo/Secret_Detection_Reports/gitleaks_report.json --verbose\n\
echo -e "\033[0;32mGitleaks scan complete.\033[0m"\n\
\n\
# Starting Detect-secrets
echo -e "\033[0;36m\n\nStarting Detect-secrets...\033[0m"; \
detect-secrets scan --all-files --exclude-files '^Secret_Detection_Reports/' --exclude-files '^talisman_html_report/' >> /repo/Secret_Detection_Reports/Detect_Secrets-Report.txt; \
echo -e "\033[0;32mDetect-Secrets scan complete.\033[0m\n"; \
\n\
# TruffleHog scan and save the report
echo -e "\033[0;36m\n\nStarting TruffleHog...\033[0m\n"\n\
/usr/local/bin/trufflehog --no-update git file:///repo --exclude-paths=/trufflehog_exclude.txt >> /repo/Secret_Detection_Reports/Trufflehog_Report.txt\n\
echo -e "\033[0;32mTruffleHog scan complete.\033[0m"\n\
\n\
echo -e "\033[0;36m\n\nStarting Talisman...\033[0m"\n\
talisman --scanWithHtml --reportDirectory=/repo/Secret_Detection_Reports\n\
if [ -d "/repo/talisman_html_report" ]; then\n\
    echo -e "\n\033[0;33mTo view the Talisman HTML report, run the following command:\033[0m"\n\
    echo -e "\033[1;92mcd talisman_html_report/ && python3 -m http.server 8000\033[0m"\n\
    echo -e "\033[0;33mThen, visit: http://localhost:8000 in your browser.\033[0m"\n\
else\n\
    echo -e "\033[0;31mTalisman HTML report directory not found\033[0m"\n\
fi\n\
' > /usr/local/bin/entrypoint.sh && \
chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the embedded script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
