function _qs_setup_mise
	# Install & check mise to standard path
	set -q MISE_INSTALL_PATH
	or set -l MISE_INSTALL_PATH "$HOME/.local/bin/mise"
	test -e $MISE_INSTALL_PATH
	and $MISE_INSTALL_PATH self-update
	or curl https://mise.run | MISE_INSTALL_PATH=$MISE_INSTALL_PATH sh

	# Create mise activate conf
	# set -l mise_script "$($MISE_INSTALL_PATH activate fish | string replace -- "$HOME" "\$HOME")"
	# eval "$mise_script"
	echo "eval \"\$($MISE_INSTALL_PATH activate fish)\"" > "$__fish_config_dir/conf.d/20-mise_activate.fish"
	eval "$($MISE_INSTALL_PATH activate fish)"

	# for mise autocomplete
	mise use -g usage
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
	mise use -g eza gdu gitui duf btop bat jq fzf fd ripgrep
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
