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
files = ['PrivacyPolicy.md', 'AboutHepC.md', 'AboutSCCS.md']

for file in files:
	print('-->  Building {}'.format(file))
	for langpath in glob.iglob(os.path.join(dir_source, '*.lproj')):
		lang = os.path.split(langpath)[-1]
		if not os.path.exists(os.path.join(langpath, file)):
			print('===>  Does not exist in {}, trying English'.format(lang))
			langpath = os.path.join(dir_source, 'en.lproj')
			if not os.path.exists(os.path.join(langpath, file)):
				print('xxx>  Also not available in English, skipping')
				continue
		
		with io.open(os.path.join(langpath, file), 'r', encoding="utf-8") as handle:
			print('--->  Reading {}'.format(lang))
			content = handle.read()
			filename = file
			title = os.path.splitext(file)[0]
			
			# markdown?
			if '.md' == os.path.splitext(file)[-1]:
				title = content.split('\n')[0]
				content = markdown.markdown(content, output_format='html5')
				filename = os.path.splitext(file)[0] + '.html'
			
			# render
			app_template.stream(title=title, content=content) \
				.dump(os.path.join(dir_target, lang, filename))
