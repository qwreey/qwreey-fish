function _qs_abbrfn_npmi
	set -l matches (string match --regex '^npmi(.*)')
	echo (echo "npm install $matches[2] " | string trim)" %"
end
