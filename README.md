WaTTS Plugin Packager
---------------------
Package WaTTS plugins for _pacman_, _apt_ and _yum_.

Synopsis
--------
You don't need to clone the repo / download a tarball of the plugin manually.
This is done by **makepkg.sh**.
This procedure is consistent with
the package-maintainers workflow
of having a build tool download the source of the to-be-built package,
instead of the developers workflow
of running a build tool inside the package source.

So, just check out *this* repo and run:
```sh
 $ ./makepkg.sh <type> <config> [curl_args...]
```
- `type` is one of `arch`, `deb` or `rpm`
- `config` is either a filesystem path or a _http(s)_ URL to a JSON encoded config file
- `curl_args` are passed to curl when downloading the config file

```sh
 $ ./makepkg.sh <config> <curl_args>
```
Same as above, but this time packages for all targets will be built (if possible on your system)

Preparation
-----------
Provide a download location for a gzipped tarball of your plugin.
Ideally (if you use _github_, _gitlab_ or similar),
tag a release and use the _download-archive_ feature on the _releases_ page.

Plugin Structure
----------------
Your repository should contain a folder `plugin/`,
everything here will be packaged to `/var/lib/watts/plugins`.
We recommend to place your config file (see below) in `pkg/config.json`,
so you can simply do `./makepkg.sh https://github.com/indigo-dc/tts_plugin_info/raw/master/pkg/config.json` or similar.

Config Schema
-------------
You also need to provide a json config file. Schema:
```js
{
    "pkg" : {
        "name" : <required, e.g. "watts-plugin-foo">,
        "short_desc" : <required, e.g. "WaTTS Foo Plugin">,
        "long_desc" : <optional, defautls to .pkg.short_desc> ,
        "version" : <required, e.g. "1.0.3">,
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
        "targz" : <optional, defaults to "https://github.com/indigo-dc/".archive.name"/archive/v".pkg.version".tar.gz">
    },
    "build": {
        "bash": <optional list, e.g. ["./configure", "make"]>
    }
}
```

- `.archive.targz` is the URL of the gzipped tarball containing the repository,
  it has to contain a single folder matching `<.archive.name>*<.pkg.version>*` (as per __find(1)__ syntax).
  Supported protocols are anything that __curl(1)__ supports, including `file://` and `http(s)://`.
  If access to the URL is restricted you can use `https://user:password@example.org/...` for HTTP basic auth.
  Other authentication methods are not supported,
  you'll have to download the archive manually and use `file://` in that case.

- `.deps.<target>` contains the dependencies for the plugin
  (The WaTTS / TTS package is _not_ included automatically, see #1).
  For each target distro you need to specify the dependencies separately,
  as the packages may be called differently in different distros.

- Each element in `.build.bash` is evaluated by bash before packaging the `plugin/` folder.
  Use this e.g. if you require your plugin to be compiled.

- Not all keys are needed for all target distros, e.g. _Arch Linux_ does not use `.pkg.maintainer` or `.pkg.long_desc`.

Dependencies
------------
- `bash`, `findutils`, `coreutils`, obviously
- `curl`, to retrieve package configs via __HTTP(S)__
- Whatever packaging for your target requires (`base-devel` on Arch Linux, `rpmdevtools` on RHEL, `dpkg` on Debian).
- `jq` - _Command-line JSON processor_, with version > 1.4.
  Older versions (like found in Ubuntu 14.04) will result in default configuration not being applied correctly.
  If you provide all optional keys in your json, your safe.

Disclaimer
----------
This is only a simple script for internal usage.
Providing invalid configuration will lead to weird, unspecified behaviour.
