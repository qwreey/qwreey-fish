function _qs_abbrfn_gl
	set -l matches (string match --regex '^gl([soga]+)' $argv[1])
	set -l flags "--decorate"

	# Push flags
	for char in (string split "" $matches[2])
		switch "$char"
			case s; set flags "$flags"" --stat"
			case o; set flags "$flags"" --oneline"
			case g; set flags "$flags"" --graph"
			case a; set flags "$flags"" --all"
		end
	end

	echo "git log $flags"
end
