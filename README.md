WaTTS Plugin Packager
=====================
Package WaTTS plugins for _pacman_, _apt_ and _yum_.

Synopsis
========
```sh
 $ ./makepkg.sh <type> <config>
```
Where `<type>` is one of `arch`, `deb` or `rpm`
and `<config>` is either a filesystem path or a _http(s)_ URL to a json encoded config file.

```sh
 $ ./makepkg.sh <config>
```
Same as above, but this time packages for all targets will be built (if possible on your system)

Preparation
===========
Provide a download location for a gzipped tarball of your plugin.
Ideally (if you use _github_, _gitlab_ or similar),
tag a release and use the _download-archive_ feature on the _releases_ page.

Plugin Structure
================
Your repository should contain a folder `plugin/`,
everything here will be packaged to `/var/lib/watts/plugins`.
We recommend to place your config file (see below) in `pkg/config.json`,
so you can simply do `./makepkg.sh https://github.com/indigo-dc/tts_plugin_info/raw/master/pkg/config.json` or similar.

Config Schema
=============
You also need to provide a json config file. Schema:
```js
{
    "pkg" : {
        "name" : <required>,
        "short_desc" : <required>,
        "long_desc" : <optional, defautls to .pkg.short_desc> ,
        "version" : <required>,
        "vendor" : <optional, defaults to .pkg.maintainer>,
        "maintainer" : <required, like "Alan Turing <alan.turing@example.org>"
    },
    "deps" : {
        "arch" : <optional list>,
        "deb" : <optional list>,
        "rpm" : <optional list>
    },
    "archive" : {
        "name" : <optional, defaults to .pgk.name>,
        "targz" : <optional, defaults to "https://github.com/indigo-dc/<.archive.name>/archive/v<.pkg.version>.tar.gz">
    }
}
```
`.archive.targz` is the gzipped tarball containing the repository,
it has to contain a single folder `<.archive.name>/<.pkg.version>`.

`.deps.<target>` contains the dependencies for the plugin (additionally to WaTTS / TTS).
For each target distro you need to specify different dependencies,
as the packages may be called differently in different distros.

Not all keys are needed for all target distros, e.g. _Arch Linux_ does not use `"pkg.maintainer"` or `"pkg.long_desc"`.

Dependencies
============
- `bash`, `findutils`, `coreutils`, obviously
- Whatever packaging for your target requires (`base-devel` on Arch Linux, `rpmdevtools` on RHEL, `dpkg` on Debian).
- `jq` - _Command-line JSON processor_, with version > 1.4.
  Older versions (like found in Ubuntu 14.04) will result in default configuration not being applied correctly.
  If you provide all optional keys in your json, your safe.

Disclaimer
==========
This is only a simple script for internal usage.
Providing invalid configuration will lead to weird, unspecified behaviour.
