function _qs_abbrfn_npmp
	set -l matches (string match --regex '^npmp(.*)')
	echo (echo "npm publish $matches[2] " | string trim)" %"
end
