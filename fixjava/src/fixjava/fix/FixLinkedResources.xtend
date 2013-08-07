package fixjava.fix

import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import fixjava.project.Link
import java.io.File

import static extension fixjava.project.EclipseProjectReader.*
import static extension fixjava.project.EclipseProjectWritter.*

class FixLinkedResources extends AbstractFix {
	
	override executeFix(ProjectFolder pf) {
		if(pf.javaNature) {
			//List of settings files:
			val fileNames = config.linkedResourcesFiles.filter[pf.mavenNature || it != "org.eclipse.m2e.core.prefs" ]
			
			//Delete files in settings:
			val settingsFolder = new File(pf.root, ".settings")
			if(settingsFolder.exists && settingsFolder.directory) {
				fileNames.forEach[settingsFolder.deleteFile(it)]
			}
			
			//Fix Project File:
			val projectFile = new File(pf.root, ".project")
			val project = projectFile.readEclipseProject
			
			//TODO: there is no consideration for existing linkedResources (they are overwritten)
			project.linkedResources = fileNames.map[fileName |
				new Link(fileName.computeLinkName, "1", fileName.computeLinkLocationURI(pf))
			].toList
			
			project.toFile(projectFile)
		}
	}
	
	def computeLinkName(String fileName) {
		return ".settings/" + fileName
	}
	
	def computeLinkLocationURI(String fileName, ProjectFolder pf) {
		return config.getLinkedResourcesLinkLocationURI(fileName, pf)
	}
	
	def deleteFile(File settingsFolder, String fileName) {
		var settingFile = new File(settingsFolder, fileName)
		if(settingFile.exists) {
			settingFile.delete
		}
	}
	
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}