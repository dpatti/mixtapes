# Mixtape Competition Server

## Setting up a dev environment

You need

* rbenv

* taglib

  * Debian/Ubuntu: `sudo apt-get install libtag1-dev`
  * Fedora/RHEL: `sudo yum install taglib-devel`
  * Homebrew: `brew install taglib`
  * MacPorts: sudo port install taglib

* A JavaScript runtime (node.js, for instance)

* Dependencies installed `bundle install --jobs=4`

* Database initialized `bundle exec rake db:migrate`

* Assets precompiled `bundle exec rake assets:precompile`

## Making it go

```sh
$ bundle exec rails s
```

## Configuration

You can control which state the app is in by changing the dates in
`config/settings/development.yml`:

```yml
contest:
  start: 2013-01-01T00:00:00.0
  rotation: 2013-01-01T00:00:00.0
  end: 2023-01-01T00:00:00.0
```
