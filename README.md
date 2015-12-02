awstats-webfaction
==================

Single installation awstats for multiple domain WebFaction hosting

What is this?
-------------

This is a project that aims to simplify the installation of the latest [awstats](http://awstats.sourceforge.net) on [WebFaction](http://www.webfaction.com?affiliate=dssw).

**It is not ready for general use.**

Install
-------

- Add a new **Static/CGI/PHP-5.4** application within your WebFaction account at https://my.webfaction.com/applications.
- `ssh` into your account and change into the application's directory:
  - `cd ~/webapps/APPNAME`
  - `git clone https://github.com/grahammiln/awstats-webfaction.git`
  - `mv awstats-webfaction/* .`
  - `mv htaccess .htaccess`
  - `rm -rf awstats-webfaction`
  - `rm index.html`

Why I am seeing Forbidden error?
--------------------------------

This installation of awstats ships with `AllowAccessFromWebToAuthenticatedUsersOnly=1`. This means an authenticated user must be viewing the statistics.