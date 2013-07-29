package fixjava.config

import fixjava.files.ProjectFolder
import java.io.File
import fixjava.files.GroupFolder

/**
 * This is an example configuration to work on the scout example
 * link: https://github.com/BSI-Business-Systems-Integration-AG/org.eclipsescout.demo
 */
class ExampleConfig implements IConfig {
	
	override getRootFile() { new File("../../org.eclipse.scout.example_repo") }
	
	override getInitialDepth() { 0 }
	
	override getLinkedResourcesFiles() {
		return #{
			"org.eclipse.core.resources.prefs",
			"org.eclipse.core.runtime.prefs",
			"org.eclipse.jdt.core.prefs",
			"org.eclipse.jdt.ui.prefs",
			"org.eclipse.pde.core.prefs",
			"org.eclipse.m2e.core.prefs"
		}
	}
	
	override getLinkedResourcesLinkLocationURI(String fileName, ProjectFolder project) {
		"PARENT-" + project.group.depth + "-PROJECT_LOC/build/org.eclipsescout.demo.settings/" + fileName
	}
	
	override getBSNExpectedDepth() { 2 }
	
	override getBSNNewNamePrefix(GroupFolder gf) 
		'''org.eclipsescout.demo.«gf.root.name»'''
	
	override getCopyright() '''
		Copyright (c) 2013 BSI Business Systems Integration AG.
		All rights reserved. This program and the accompanying materials
		are made available under the terms of the Eclipse Public License v1.0
		which accompanies this distribution, and is available at
		http://www.eclipse.org/legal/epl-v10.html
		
		Contributors:
		    BSI Business Systems Integration AG - initial API and implementation
	'''
	
	override getAboutFile() {
		new File(new File(new File(getRootFile(), "build"), "org.eclipsescout.demo.settings"), "about.html")
	}
	
	override getParentGroupId() { "org.eclipsescout.demo" }
	
	override getParentArtifactId() { "org.eclipsescout.demo.master" }
	
	override getParentRelativePath() {"../../build/org.eclipsescout.demo.master/"}
}