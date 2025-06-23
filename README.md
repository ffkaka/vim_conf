# Things to do for evironment
need at least neovim v0.11.1

nvim-lspconfig need to do a more job
```bash
$ git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
$ npm i -g pyright neovim
```

```bash
$ brew install 
$ brew tap homebrew/cask-fonts
$ brew install font-meslo-lg-nerd-font
# $ brew install font-hack-nerd-font
go install golang.org/x/tools/gopls@latest
```

```bash
# in linux
$ sudo apt install ripgrep
$ sudo apt install fzf
# install font-eslo-lg-nerd-font in ubuntu
$ sudo apt install fonts-meslo
```

## for jdtls setup
download jdtls from https://download.eclipse.org/jdtls/milestones/
extract it to ${HOME}/java/
replace org.eclipse.equinox.launcher_*.jar file location in nvim-jdtls.lua to the extracted location
### for project
make a .project and .classpath file in the project root directory
need "jdtls/bin" directory to be executable

## for video reference
https://youtu.be/m8C0Cq9Uv9o?si=9d1DER-YaQUBqQim

## for git reference
https://github.com/nvim-lua/kickstart.nvim

## for gopls
go install golang.org/x/tools/gopls@latest
set env GOPATH=$HOME/go
