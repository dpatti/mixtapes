# Mixtape Competition Server

## dev

You need taglib:

```
Debian/Ubuntu: sudo apt-get install libtag1-dev
Fedora/RHEL: sudo yum install taglib-devel
Brew: brew install taglib
MacPorts: sudo port install taglib
```

And a javascript runtime (node.js, for instance).

Then make it go:

```
$ rails s
```

You can control which state the app is in by changing the dates in
`config/settings/development.yml`:

```yml
contest:
  start: 2013-01-01T00:00:00.0
  rotation: 2013-01-01T00:00:00.0
  end: 2023-01-01T00:00:00.0
```
