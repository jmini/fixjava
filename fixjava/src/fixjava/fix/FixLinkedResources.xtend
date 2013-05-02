package fixjava.fix

import fixjava.files.ProjectFolder
import java.io.File
import java.util.ArrayList

import static extension fixjava.files.XmlExtensions.*
import com.google.common.io.Files
import com.google.common.base.Charsets
import fixjava.config.IConfig

class FixLinkedResources extends AbstractFix {
	
	override executeFix(ProjectFolder pf) {
		if(pf.javaNature) {
			//List of settings files:
			val fileNames = config.getLinkedResourcesFiles(pf)
			
			//Delete files in settings:
			val settingsFolder = new File(pf.root, ".settings")
			if(settingsFolder.exists && settingsFolder.directory) {
				fileNames.forEach[settingsFolder.deleteFile(it)]
			}
			
			//Fix Project File:
			val projectFile = new File(pf.root, ".project")
			val content = Files::readLines(projectFile, Charsets::UTF_8).map[it.trim].join
			val doc = content.toDocument;
			
			val malformedLink = new ArrayList<String>
			val existingLink = new ArrayList<String>
			
			val links = doc.selectByXPathQuery("/projectDescription/linkedResources/link");
			links.forEach[
				val fileName = it.childNode("name").textContent.computeFileName
				if(it.childNode("type").textContent != "1" ||
					it.childNode("locationURI").textContent != fileName.computeLinkLocationURI(pf)) {
						malformedLink.add = fileName
				} else {
					existingLink.add = fileName
				}
			]
			
			val projectDescription = doc.childNode("projectDescription")
			val linkedResources = projectDescription.getOrCreateChildNode("linkedResources", doc)
			//TODO: remove malformedLink.
			
			fileNames.filter[!existingLink.contains(it)].forEach[
				val fileName = it
				val link = linkedResources.appendChild(doc.createElement("link"))
				
				link.appendChild(doc.createElement("name") => [setTextContent = fileName.computeLinkName])
				link.appendChild(doc.createElement("type") => [setTextContent = "1"])
				link.appendChild(doc.createElement("locationURI") => [setTextContent = fileName.computeLinkLocationURI(pf)])
			]
			
			var cnt = doc.toXml
			cnt = cnt.replaceAll('<\\?xml version="1\\.0" encoding="UTF-8"\\?><projectDescription>', '<?xml version="1.0" encoding="UTF-8"?>\n<projectDescription>')
			cnt = cnt.replaceAll("<comment/>", "<comment></comment>")
			cnt = cnt.replaceAll("(\\s+)<projects/>", "$1<projects>$1</projects>")
			cnt = cnt.replaceAll("(\\s+)<arguments/>", "$1<arguments>$1</arguments>")
			cnt = cnt.replaceAll("    ", "\t")
			
//			println(cnt)
//			println(projectFile.absolutePath)
			Files::write(cnt, projectFile, Charsets::UTF_8)
		}
	}
	
	def computeFileName(String linkName) {
		return linkName.replace(".settings/", "")
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