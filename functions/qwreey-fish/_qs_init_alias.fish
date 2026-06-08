function _qs_init_alias
    # Add color support
	alias dir='dir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'

	# Sudo alias
	not command --query sd
	and alias sd='sudo'

	# Define default ls, long ls, all ls
	alias ls='eza --color=always --group-directories-first --icons=always'
	alias ll='eza -l --color=always --group-directories-first --icons=always'
	alias la='eza -al --color=always --group-directories-first --icons=always'

	# Git alias
	alias g='git'
end
