function _qs_init_alias
    # Add color support
    command -q dir
	and alias dir='dir --color=auto'
	command -q grep
	and alias grep='grep --color=auto'
	command -q fgrep
	and alias fgrep='fgrep --color=auto'
	command -q egrep
	and alias egrep='egrep --color=auto'

	# Sudo alias
	command -q sudo
	and not command -q sd
	and alias sd='sudo'

	# Define default ls, long ls, all ls
	if command -q eza
		alias ls='eza --color=always --group-directories-first --icons=always'
		alias ll='eza -l --color=always --group-directories-first --icons=always'
		alias la='eza -al --color=always --group-directories-first --icons=always'
	end

	# Git alias
	command -q git
	and not command -q g
	and alias g='git'
end
