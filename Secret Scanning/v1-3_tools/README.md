Currently this Docker script supports only 3 tools 

    - Git Leaks
    - Gitty Leaks
    - Talisman

### Features

- It finds secrets in your git repo/branch utlilizing different tools. 

- Shows the result in *cli*, runs on a docker image that gets deleted automatically

- results gets saved in local computer once its finished

### How to run
[NECESSARY]  For the tool to run properly, _git clone_ the specific branch you have to review

open docker desktop/docker daemon

build this docker image with,
`docker build -t secrets-checker .`

after its built, go where the repo is. run it with command, `docker run -it --rm -v "$(PWD):/repo" secrets-checker && cd talisman_html_report/ && python3 -m http.server 8000`

report will be saved in the repo, in folder *Secret_Detection_Reports* and *talisman_html_report* in the root directory of local computer

for visiting the Talisman HTML file, goto http://localhost:8000/ in the browser, once reviewing the html file is done. STOP the server in the terminal
