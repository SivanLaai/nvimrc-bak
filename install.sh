if ! command -v git >/dev/null; then
	abort "$(
		cat <<EOABORT
You must install Git before installing this Nvim config. See:
  ${tty_underline}https://git-scm.com/${tty_reset}
EOABORT
	)"
fi

check_ssh() {
	echo "Validating SSH connection..."
	ssh -T git@github.com &>/dev/null
	if ! [ $? -eq 1 ]; then
		echo "We'll use HTTPS to fetch and update plugins."
		return 0
	else
		echo "Do you prefer to use SSH to fetch and update plugins? (otherwise HTTPS) [Y/n] "
		read -r USR_CHOICE
		if [[ $USR_CHOICE == [nN] || $USR_CHOICE == [Nn][Oo] ]]; then
			return 0
		else
			return 1
		fi
	fi
}

input() {
	echo "select your choose [Y/n]: "
	read -r USR_CHOICE
	if [[ $USR_CHOICE == [nN] || $USR_CHOICE == [Nn][Oo] ]]; then
		echo 0
		return 0
	else
		echo 1
		return 1
	fi
}

DEST_DIR="${HOME}/.config/nvim"
USE_SSH=1

if check_ssh; then
	USE_SSH=0
fi

git_prefix_url="git@github.com:"

if [ "$USE_SSH" -eq "1" ]; then
	echo "Changing default fetching method to SSH..."
else
	echo "Changing default fetching method to HTTPS..."
	git_prefix_url="https://github.com/"
fi
cd ~
HOME=$(pwd)
##### 安装方式
## 配置vim 将vim打造成一个轻量的IDE
## linux安装
#### tmux安装
echo "Y - Install tmux, N - skip"
input
choose=$?
if [ "$choose" -eq "1" ]; then
	USE_SSH=0
	echo "now installing tmux"
	sudo apt install libevent-dev libncurses5-dev
	sudo apt install tmux
	# 配置tmux支持快捷键与vim无缝切换
	if [ ! -e "$HOME/.tmux.conf" ]; then
		touch ~/.tmux.conf
	else
		rm ~/.tmux.conf
	fi

	cat >>~/.tmux.conf <<-"eof"
		# VIM模式
		bind-key k select-pane -U # up
		bind-key j select-pane -D # down
		bind-key h select-pane -L # left
		bind-key l select-pane -R # right
		#开启鼠标
		set -g mouse on
		#设置vim模式
		setw -g mode-keys vi
		#设置tmux的颜色模式
		set -g default-terminal "screen-256color"
	eof
fi
#Ubuntu
#### python安装
echo "Y - Install Python, N - skip"
echo "Please Choose your Environment:"
input
choose=$?
if [ "$choose" -eq "1" ]; then
	#### 1编译python3.8.12
	echo "choose Normal Enviroment for using lightly"
	if [ ! -e "Python-3.8.12.tar.xz" ]; then
		echo "Downloading Python Install Package."
		sudo apt-get install build-essential
		sudo apt install -y zlib1g zlib1g-dev libffi-dev openssl libssl-dev libbz2-dev liblzma-dev libsqlite3-dev libmysqlclient-dev
		wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tar.xz
	fi

	if [ ! -e "/usr/local/python3.8/lib/python3.8/config-3.8-x86_64-linux-gnu" ]; then
		echo "compiling and installing Python."
		tar -xvf Python-3.8.12.tar.xz
		cd Python-3.8.12
		./configure --enable-shared --enable-optimizations --prefix=/usr/local/python3.8
		sudo make altinstall -j8
		# add bin path
		#echo 'export PATH=/usr/local/python3.8/bin:$PATH'>>~/.zshenv
		#echo 'export PYTHONHOME=/usr/local/python3.8'>>~/.zshenv
		cd ~
		echo '/usr/local/python3.8/lib' >>python.conf
		sudo mv python.conf /etc/ld.so.conf.d/python.conf
		sudo ldconfig
		sudo rm -rf Python-3.8.12
		sudo rm /usr/bin/python3
		sudo rm /usr/bin/pip3
		sudo ln -s /usr/local/python3.8/bin/python3.8 /usr/bin/python3
		sudo ln -s /usr/local/python3.8/bin/pip3.8 /usr/bin/pip3
		/usr/local/python3.8/bin/python3.8 -m pip install --user --upgrade pip
		cd ~
		/usr/local/python3.8/bin/python3.8 -m virtualenv venv
		echo 'source ~/venv/bin/activate' >>~/.zshenv
		source ~/venv/bin/activate venv
		rm -rf Python-3.8.12*
	fi
fi

echo "Y - NeoVim, N - Skip"
input
choose=$?
if [ "$choose" -eq "1" ]; then
	echo "dpkg install Neovim..."
	if [ ! -e "nvim-linux64.deb" ]; then
		wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
		sudo dpkg -i nvim-linux64.deb
	fi
	# 备份nvim设置
	if [[ -d "${DEST_DIR}" ]]; then
		mv -f ${DEST_DIR} ${DEST_DIR}_$(date +%Y%m%dT%H%M%S)
	fi
	echo "Y - install MyNeovimRC UI, N - Skip"
	input
	choose=$?
	if [ "$choose" -eq "1" ]; then
		sudo apt-get install ripgrep #fd
		mkdir -p ${DEST_DIR}
		cd ~/nvimrc
		cp -rf * ${DEST_DIR}
	fi
	echo "Y - install packer.nvim, N - Skip"
	input
	choose=$?
	if [ "$choose" -eq "1" ]; then
		git clone --depth 1 ${git_prefix_url}wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
	fi
fi

# 编译nodejs,插件coc需要nodejs的功能
# 安装nodejs, 插件coc.vim会用到这个软件
cd ~

echo "Y - Install Node, N - skip"
echo "Please Choose your Environment:"
input
choose=$?
if [ "$choose" -eq "1" ]; then
	if [ ! -e "node-v14.17.1-linux-x64.tar.xz" ]; then
		echo "Downloading node-v14.17.1 Install Package."
		wget https://nodejs.org/dist/v14.17.1/node-v14.17.1-linux-x64.tar.xz
	fi

	if [ ! -e "/usr/local/bin/node" ]; then
		tar -xf node-v14.17.1-linux-x64.tar.xz
		echo "installing nodejs"
		sudo cp -rf node-v14.17.1-linux-x64/bin/* /usr/local/bin
		sudo cp -rf node-v14.17.1-linux-x64/share/* /usr/local/share
		sudo cp -rf node-v14.17.1-linux-x64/lib/* /usr/local/lib
	fi
fi

#添加环境变量
bash_file="~/.zshenv"
if [ ! -e "$HOME/.zshenv" ]; then
	touch $HOME/.zshenv
#	echo 'export TERM=xterm-256color' >>~/.zshenv
fi

#### zsh安装
if [ ! -x "$(command -v zsh)" ]; then
	echo 'zsh is not installed.' >&2
	echo 'installing zsh now.' >&2
	sudo apt install zsh
else
	echo 'zsh is installed'
fi

install_zsh_packages() {
	# zsh-zutoggestions
	git clone ${git_prefix_url}zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	# zsh-syntax-highlighting
	git clone ${git_prefix_url}zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	# autojump
	git clone ${git_prefix_url}wting/autojump.git
	cd autojump
	./install.py
	#添加autojump到zsh
	output=$(cat ~/.zshrc | grep "autojump.sh")
	if [ ! -n "$output" ]; then
		echo '[[ -s ~/.autojump/etc/profile.d/autojump.sh ]] && . ~/.autojump/etc/profile.d/autojump.sh' >>~/.zshrc
		echo 'autoload -U compinit && compinit -u' >>~/.zshrc
	fi

	git clone --depth=1 ${git_prefix_url}romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	sed -i 's#"robbyrussell"#"powerlevel10k/powerlevel10k"#g' ~/.zshrc
	sed -i 's#"plugins=(git)"#"plugins=(git autojump zsh-autosuggestions zsh-syntax-highlighting)"#g' ~/.zshrc
}
#安装oh-my-zsh
echo "Y - Install ohmyzsh, N - skip"
input
choose=$?
if [ "$choose" -eq "1" ]; then
	rm -rf $HOME/.oh-my-zsh
	if [ ! -d "$HOME/ohmyzsh" ]; then
		echo 'installing oh-my-zsh now.' >&2
		cd ~
		output=$(git clone ${git_prefix_url}ohmyzsh/ohmyzsh.git)
		echo $output
		cd $HOME/ohmyzsh/tools
		#install theme
		./install.sh
		install_zsh_packages
		rm -rf $HOME/ohmyzsh
	else
		echo 'ohmyzsh had been cloned, now reinstall oh-my-zsh'
		cd $HOME/ohmyzsh/tools
		#install theme
		./install.sh
		install_zsh_packages
		rm -rf $HOME/ohmyzsh
	fi
fi

#激活环境bash变量
output=$(cat ~/.zshrc | grep "zshenv")
if [ ! -n "$output" ]; then
	echo 'alias tmux="tmux -2"' >>~/.zshenv
	echo 'source ~/.zshenv' >>~/.zshrc
fi

echo "nvim +PackerSync"
