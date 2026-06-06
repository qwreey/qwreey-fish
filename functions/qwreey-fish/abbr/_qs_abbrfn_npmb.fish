function _qs_abbrfn_npmb
	set -l matches (string match --regex '^npmb(.*)')
	echo (echo "npm build $matches[2] " | string trim)" %"
end
