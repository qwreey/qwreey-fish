function _qs_abbrfn_gcm
	set -l matches (string match --regex '^gcm([^.]+)\.?(.*)' $argv[1])
	echo "git commit -m \"$(_qs_gen_commitheader $matches[2] $matches[3]): %\""
end
