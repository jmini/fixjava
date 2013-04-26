package fixjava.config

import fixjava.files.ProjectFolder
import java.io.File
import java.util.ArrayList

/**
 * This is an example configuration to work on the scout example
 * link: https://github.com/BSI-Business-Systems-Integration-AG/org.eclipsescout.demo
 */
class ExampleConfig implements IConfig {
	
	override getRootFile() { new File("../../org.eclipse.scout.example_repo") }
	
	override getInitialDepth() { 0 }
	
	override getLinkedResourcesFiles(ProjectFolder project) {
		val list =new ArrayList<String> => [
			add = "org.eclipse.core.resources.prefs"
			add = "org.eclipse.core.runtime.prefs"
			add = "org.eclipse.jdt.core.prefs"
			add = "org.eclipse.jdt.ui.prefs"
			add = "org.eclipse.pde.core.prefs"
		]
		if(project.mavenNature) {
			list.add = "org.eclipse.m2e.core.prefs"
		}
		list
	}
	
	override getLinkedResourcesLinkLocationURI(String fileName, ProjectFolder project) {
		"PARENT-" + project.depth + "-PROJECT_LOC/build/org.eclipsescout.demo.settings/" + fileName
	}
	
	override getBSNExpectedDepth() { 2 }
	
	override getBSNNewNamePrefix(ProjectFolder pf) {
		val parent = pf.root.parentFile.name
		"org.eclipsescout.demo."+parent
	}
}