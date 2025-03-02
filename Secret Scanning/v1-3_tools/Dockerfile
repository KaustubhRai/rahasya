# Use a base image with Python, git, and other necessary tools
FROM python:3.13-slim-bullseye

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

# Install Talisman
RUN wget -O /usr/local/bin/talisman https://github.com/thoughtworks/talisman/releases/download/v1.32.0/talisman_linux_amd64 && \
    chmod +x /usr/local/bin/talisman

# Install Talisman HTML Report
RUN mkdir -p ~/.talisman && \
    curl https://github.com/jaydeepc/talisman-html-report/archive/v1.3.zip  -o ~/.talisman/talisman_html_report.zip -J -L && \
    cd ~/.talisman && \
    unzip talisman_html_report.zip -d . && \
    mv talisman-html-report-1.3 talisman_html_report && \
    rm talisman_html_report.zip

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

# Update the entrypoint script
RUN echo '#!/bin/bash\n\
\n\
# Ensure we are in the mounted Git repository directory\n\
if [ ! -d "/repo/.git" ]; then\n\
    echo "Error: Git repository not found in /repo"\n\
    exit 1\n\
fi\n\
cd /repo\n\
\n\
mkdir -p /repo/Secret_Detection_Reports\n\
\n\
echo "\n\nStarting gittyleaks..."\n\
gittyleaks --find-anything | tee /repo/Secret_Detection_Reports/gittyleaks_report.txt\n\
python /usr/local/bin/clean_gittyleaks_report.py /repo/Secret_Detection_Reports/gittyleaks_report.txt\n\
\n\
echo "\n\nStarting gitleaks..."\n\
gitleaks detect --source=. --report-format=json --report-path=/repo/Secret_Detection_Reports/gitleaks_report.json\n\
\n\
echo "\n\nStarting Talisman..."\n\
talisman --scanWithHtml --reportDirectory=/repo/Secret_Detection_Reports\n\
\n\
# Check if the Talisman HTML report directory exists\n\
if [ -d "/repo/Secret_Detection_Reports/talisman_reports/data" ]; then\n\
    # Start an HTTP server in the Talisman HTML report directory\n\
    cd /repo/Secret_Detection_Reports/talisman_reports/data\n\
    python -m http.server 8000 &\n\
else\n\
    echo "Talisman HTML report directory not found"\n\
fi\n\
' > /usr/local/bin/entrypoint.sh && \
chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to the embedded script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]