Small Web Hexagon
==========

Illustration of the user port of the hexagon, for a small Content Management System.
The CMS at this point only allows adding text "muffins" (content) and reading them.
(So far only the user port is included, not the persistence port).

Two adapters/drivers, a test set going straight to the user port API and getting a struct back,
and a UI adapter (Ruby Rack and Erubis html_from_templatefile) allowing web usage.

Run config.ru to get the web UI on port 9292
Run test_muffinland to run the tests.



