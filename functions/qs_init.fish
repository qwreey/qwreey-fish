function qs_init
	set --query _qs_inited
	or set --global fish_function_path (path resolve $__fish_config_dir/functions/qwreey-fish/**/) $fish_function_path
	set --global _qs_inited

	_qs_init_abbr
	_qs_init_alias
	# _qs_init_magicenter

	fish_add_path -a $HOME/.local/bin
	or true
end
