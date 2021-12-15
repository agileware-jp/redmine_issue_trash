# Redmine Issue Trash plugin

This plugin allows you to restore Issues deleted by accident.

## Requirements
Redmine 4.2.x or higher.

## Getting started

### 1. Install the plugin

```shell
cd {LOCAL_REDMINE_DIRECTORY}/plugins
```

#### From downloaded release archive file

```shell
tar xvzpf redmine_issue_trash....
```

#### or via Git clone

```shell
git clone https://github.com/agileware-jp/redmine_issue_trash.git
```

#### Install gems and migrate the database

```shell
cd {LOCAL_REDMINE_DIRECTORY}
bundle install
bundle exec rake redmine:plugins:migrate
```

#### Restart you Redmine

After restart, also check if plugin is listed in the installed Redmine plugins list - _(Administration|Plugins)_

## Uninstall

Try this:

* rails redmine:plugins:migrate NAME=redmine_issue_trash VERSION=0
    RAILS_ENV=production
    
## Description and usage info

* <https://github.com/agileware-jp/redmine_issue_trash/wiki>

## License

Copyright &copy; 2021 [Agileware Inc.](http://agileware.jp)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
