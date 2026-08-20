# mise packages that don't have a working build for Termux/Android and
# have no native Termux package either; just skip them there.
set -g _qs_mise_termux_ignore usage btop

# mise packages that don't have a working build for Termux/Android but do
# have a native Termux package; install these via `pkg` there instead.
# Format: misepkgname:pkgname
set -g _qs_mise_termux_native \
	eza:eza gdu:gdu gitui:gitui duf:duf bat:bat jq:jq fzf:fzf fd:fd ripgrep:ripgrep

function _qs_mise_termux_native_lookup --argument-names pkgname
	for entry in $_qs_mise_termux_native
		set -l parts (string split ":" $entry)
		test "$parts[1]" = "$pkgname"
		and echo $parts[2]
		and return 0
	end
	return 1
end

# Wrapper around `mise use -g` that, on Termux, drops packages in
# $_qs_mise_termux_ignore and installs packages in $_qs_mise_termux_native
# via `pkg` instead of mise.
function _qs_mise_use
	if not set -q TERMUX_VERSION
		mise use -g $argv
		return
	end

	set -l mise_packages
	set -l native_packages
	for pkgname in $argv
		contains -- $pkgname $_qs_mise_termux_ignore
		and continue
		set -l native_name (_qs_mise_termux_native_lookup $pkgname)
		if test $status -eq 0
			set -a native_packages $native_name
		else
			set -a mise_packages $pkgname
		end
	end

	test (count $native_packages) -gt 0
	and pkg install -y $native_packages
	test (count $mise_packages) -gt 0
	and mise use -g $mise_packages
	return 0
end

function _qs_setup_mise
	# Install & check mise to standard path
	if set -q TERMUX_VERSION
		# Termux ships mise as a pkg; install/upgrade through pkg and point at its binary
		pkg install -y mise
		set -f MISE_INSTALL_PATH "$PREFIX/bin/mise"
	else
		set -q MISE_INSTALL_PATH
		or set -f MISE_INSTALL_PATH "$HOME/.local/bin/mise"
		test -e $MISE_INSTALL_PATH
		and $MISE_INSTALL_PATH self-update
		or curl https://mise.run | MISE_INSTALL_PATH=$MISE_INSTALL_PATH sh
	end

	# Create mise activate conf
	# set -l mise_script "$($MISE_INSTALL_PATH activate fish | string replace -- "$HOME" "\$HOME")"
	# eval "$mise_script"
	echo "eval \"\$($MISE_INSTALL_PATH activate fish)\"" > "$__fish_config_dir/conf.d/20-mise_activate.fish"
	eval "$($MISE_INSTALL_PATH activate fish)"

	# for mise autocomplete
	_qs_mise_use usage
end

function _qs_setup_carapace
	set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
	mise use -g carapace@latest
	set -l carapace_script "$(carapace _carapace fish | string replace -- "$HOME" "\$HOME")"
	echo "$carapace_script" > "$__fish_config_dir/conf.d/30-carapace_activate.fish"
	eval "$carapace_script"
end

function _qs_setup_fisher
	if not command --query fisher
		curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
		or return 1
	end
	fisher install jorgebucaran/fisher
end

function _qs_setup_bin
	# aqua:ogham/dog not works
	_qs_mise_use eza gdu gitui duf btop bat jq fzf fd ripgrep
end

function _qs_setup_plugin
	fisher install \
		jorgebucaran/fisher qwreey/quietline-fish \
		nickeb96/puffer-fish jorgebucaran/autopair.fish \
		qwreey/qwreey-fish
end

function qs_setup; argparse --max-args 0 \
	'with-carapace' \
	'without-mise' \
	'without-bin' \
-- $argv
	_qs_setup_fisher
	if not set -q _flag_without_mise
		_qs_setup_mise
		set -q _flag_without_bin
		or _qs_setup_bin
	end
	_qs_setup_plugin
	set -q _flag_with_carapace
	and _qs_setup_carapace
end
