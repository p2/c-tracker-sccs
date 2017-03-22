#!/usr/bin/env python3
#
#  Uses Markdown and HTML data from _source and renders them, using Jinja2, into _target
#
#  Requirements:
#  - jinja2
#  - markdown

_template_dir = 'content-templates'
_template_name = 'App.html'
_source = 'c-tracker-sccs-content'
_target = 'App'
_files = [
	'PrivacyPolicy.md',
	'LicenseAgreement.md',
	'AboutHepC.md',
	'AboutSCCS.md',
	'AboutTheStudy.md',
	'HowItWorks.md',
	(['AboutTheStudy.md', 'HowItWorks.md'], 'StudyAndHowItWorks.html'),
	'WhoCanParticipate.md'
]

if '__main__' == __name__:
	exec(open('c-tracker-sccs-content/build.py').read())
	run(_template_dir, _template_name, _source, _target, _files)

