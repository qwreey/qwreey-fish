function _qs_get_gitdir
	# Get git dir
	set -l gitdir (git rev-parse --absolute-git-dir)
	or return 1
	set gitdir (realpath "$gitdir/../")
	echo "$gitdir"
end
