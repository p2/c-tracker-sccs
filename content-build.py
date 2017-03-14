#!/usr/bin/env python3
#
#  Uses HTML data from c-tracker-sccs-content and renders them, using Jinja2, into CTracker/HTMLContent/
#
#  Requirements:
#  - jinja2
#  - markdown

import io
import glob
import os.path
import markdown
from jinja2 import Environment, PackageLoader


env = Environment(loader=PackageLoader(__name__, 'content-templates'))
app_template = env.get_template('App.html')
dir_source = 'c-tracker-sccs-content'
dir_target = 'App'
files = [
	'PrivacyPolicy.md',
	'LicenseAgreement.md',
	'AboutHepC.md',
	'AboutSCCS.md',
	'AboutTheStudy.md',
	'HowItWorks.md',
	(['AboutTheStudy.md', 'HowItWorks.md'], 'StudyAndHowItWorks.html'),
	'WhoCanParticipate.md'
]

def lang_name(langpath):
	return os.path.splitext(os.path.split(langpath)[-1])[0]

def file_content(langpath, filename):
	filepath = os.path.join(langpath, filename)
	
	# not found in desired language, fall back to en
	if not os.path.exists(filepath):
		print('~~~>  «{}» does not exist in {}, trying English for'.format(filename, lang_name(langpath)))
		altpath = os.path.join(dir_source, 'en.lproj')
		filepath = os.path.join(altpath, filename)
		if not os.path.exists(filepath):
			print('xxx>  «{}» not found, skipping'.format(file))
			return None, None, None
	
	# read file
	with io.open(filepath, 'r', encoding="utf-8") as handle:
		content = handle.read()
		title = os.path.splitext(filename)[0]
		
		# markdown?
		if '.md' == os.path.splitext(filename)[-1]:
			filename = os.path.splitext(filename)[0] + '.html'
			title = content.split('\n')[0]
			content = markdown.markdown(content, output_format='html5')
	
	return filename, title, content

for langpath in glob.iglob(os.path.join(dir_source, '*.lproj')):
	print('->  Language {}'.format(lang_name(langpath)))
	langdir = os.path.split(langpath)[-1]
	
	for file in files:
		filename = None
		title = None
		content = []
		
		# read file(s): expecting either a string (one file) or a tuple with a
		# list of files (0) and the target file name (1)
		subfiles = [file]
		if isinstance(file, tuple):
			subfiles = file[0]
			filename = file[1]
		
		for subfile in subfiles:
			myname, mytitle, mycontent = file_content(langpath, subfile)
			if filename is None:
				filename = myname
			if title is None:
				title = mytitle
			if mycontent is not None:
				content.append(mycontent)
		if 0 == len(content):
			continue
		
		# render
		app_template.stream(title=title, content='\n\n'.join(content)) \
			.dump(os.path.join(dir_target, langdir, filename))
