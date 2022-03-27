# This is file can be source to any shell supporting alias directive

alias di="docker images --format \"table {{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}\""
alias dri="docker rmi"
alias dc="docker ps -a --format \"table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\""
alias di-size="docker ps -a --format \"table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Size}}\t{{.Status}}\""
alias dcr="docker rm -f"
alias dcs="docker container stop"
alias dcom="docker commit"
alias dock-r="dock -u root"
