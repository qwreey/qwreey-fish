function _qs_init_magicenter
	function _qs_magicenter
		if test -z (commandline)

		end
		commandline -f execute
	end

	bind \r _qs_magicenter
	if functions -q fish_vi_key_bindings
		bind -M insert \r _qs_magicenter
		bind -M default \r _qs_magicenter
	end
end
