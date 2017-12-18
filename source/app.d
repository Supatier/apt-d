import std.stdio;
import core.stdc.stdlib;
import std.array;
import std.exception, std.process;
import std.algorithm;
import std.conv;
import core.sys.posix.unistd;
import core.exception;

void usage() {
	writeln("
apt
Usage:	apt command [options]
	apt help command [options]

Commands:
	add-repository	- Add entries to apt sources.list
	autoclean	- Erase old downloaded archive files
	autoremove	- Remove automaticlly all unused packages
	build		- Build binary or source packages from sources
	build-dep	- Configure build-dependencies for source packages
	changelog	- View a package's chagelog
	check		- Verify that there are no broken dependencies
	clean		- Erase downloaded archive files
	contains	- List packages containing a file
	content		- List files contained in a package
	deb		- Install a .deb package
	depends		- Show raw dependency information for a package
	dist-upgrade	- Upgrade the system by removing/installing/upgrading packages
	download	- Download the .deb file for a package
	edit-sources	- Edit /etc/apt/sources.list with your preferred text editor
	dselect-upgrade - Follow dselect selections
	full-upgrade    - Same as 'dist-upgrade'
	held		- List all help packages
	help		- Show help for a command
	hold		- Hold a package
	install		- Install/upgrade packages
	list		- List packages based on package names
	policy		- Show policy settings
	purge		- Remove packages and their configuration files
	recmomends	- List missing recommended packages for a particular package
	rdepends	- Show reverse dependency information for a package
	reinstall	- Download and (possibly) reinstall a currently installed package
	remove		- Remove packages
	search		- Search for a package by name and/or expression
	show		- Display detailed information about a package
	showhold	- Same as 'held'
	source		- Download source archives
	sources		- Same as 'edit-sources'
	unhold		- Unhold a package
	update		- Download lists of new/upgradable packages
	upgrade		- Perform a safe upgrade
	version		- Show the installed version of a package
	");
	exit(EXIT_FAILURE);
}

void main(string[] args) {
	immutable string[string] aliases = [
		"dist-upgrade" : "full-upgrade", "sources" : "edit-sources", "held" : "showhold"
	];
	if (args.length < 2) {
		usage();
	}
	auto argcommand = args[1];
	auto argopt = args[2 .. $];
	auto argoptions = "";
	if (argopt.length != 0) {
		argoptions = argopt[0];
	}
	auto command = "";
	bool showHelp, sort, highlight = false;
	if (argcommand == "help") {
		if (args.length < 3) {
			usage();
		}
		showHelp = true;
		argcommand = args[2];
		//argoptions = args[3 .. $];
	}

	if (argcommand in aliases) {
		argcommand = aliases[argcommand];
	}

	if (["autoremove", "list", "show", "install", "remove", "purge", "update",
			"upgrade", "full-upgrade", "edit-sources"].canFind(argcommand)) {
		// apt
		command = text("/usr/bin/apt ", argcommand, " ", argoptions);
	} else if (["clean", "dselect-upgrade", "build-dep", "check",
			"autoclean", "source", "moo"].canFind(argcommand)) {
		// apt-get
		command = text("apt-get ", argcommand, " ", argoptions);
	} else if (["changelog", "reinstall"].canFind(argcommand)) {
		// aptitude
		command = text("aptitude ", argcommand, " ", argoptions);
	} else if (["stats", "depends", "rdepends", "policy"].canFind(argcommand)) {
		// apt-cache
		command = text("apt-cache ", argcommand, " ", argoptions);
	} else if (["recommends"].canFind(argcommand)) {
		command = text("/usr/lib/linuxmint/mintsystem/mint-apt-recommends.py ", argoptions);
	} else if (["showhold", "hold", "unhold"].canFind(argcommand)) {
		// apt-mark
		command = text("apt-mark ", argcommand, " ", argoptions);
	} else if (["markauto", "markmanual"].canFind(argcommand)) {
		// apt-mark
		command = text("apt-mark ", argcommand[4 .. $], argoptions);
	} else if (argcommand == "contains") {
		command = text("dpkg -S ", argoptions);
	} else if (argcommand == "content") {
		command = text("dpkg -L ", argoptions);
	} else if (argcommand == "deb") {
		command = text("dpkg -i ", argoptions);
	} else if (argcommand == "build") {
		command = text("dpkg-buildpackage ", argoptions);
	} else if (argcommand == "version") {
		command = text("/usr/lib/linuxmint/common/version.py %s", argoptions);
	} else if (argcommand == "download") {
		command = text("/usr/lib/linuxmint/mintsystem/mint-apt-download.py ", argoptions);
	} else if (argcommand == "add-repository") {
		command = text("add-apt-repository ", argoptions);
	} else if (argcommand == "search") {
		auto sSize = text(" ", executeShell("stty size"), " ");
		//enforce(sSize.status == 0);
		auto nex = sSize.split;
		auto columns = nex[1];
		command = text("aptitude -w ", columns, " ", argcommand, " ", argoptions);
	} else {
		usage();
	}

	auto uid = getuid();
	if (uid != 0 && ["autoremove", "install", "remove", "purge", "update", "upgrade", "full-upgrade",
			"edit-sources", "clean", "dselect-upgrade", "build-dep",
			"check", "autoclean", "reinstall", "deb",
			"hold", "unhold", "add-repository", "markauto", "markmanual"].canFind(
			argcommand)) {
		command = text("sudo ", command);
	}

	if (["content", "version", "policy", "depends", "rdepends",
			"search"].canFind(argcommand) && argoptions.length > 1) {
		highlight = true;
	}

	if (["content", "contains"].canFind(argcommand)) {
		sort = true;
	}

	if (showHelp) {
		write("\"apt ", argcommand, " ", argoptions,
				"\" is equivalent to \"", command, "\"");
	} else {
		auto pid = spawnShell(command, stdin, stdout);
		scope (exit)
			wait(pid);
	}
	// Todo : highlight, sort
}
