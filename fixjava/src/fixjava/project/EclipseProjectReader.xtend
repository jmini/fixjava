package fixjava.project

import static extension xtend.XmlExtensions.*
import org.w3c.dom.Document
import java.io.File

class EclipseProjectReader {
	
	def static readEclipseProject(File file) {
		file.toDocument.readEclipseProject
	}
	
	def static readEclipseProject(String content) {
		content.toDocument.readEclipseProject
	}
	
	def static readEclipseProject(Document doc) {
		new EclipseProject => [
			name = doc.selectByXPathQuery("/projectDescription/name").head.textContent
			comment = doc.selectByXPathQuery("/projectDescription/comment").head.textContent
			buildCommands = doc.selectByXPathQuery("/projectDescription/buildSpec/buildCommand/name").map[textContent]
			natures = doc.selectByXPathQuery("/projectDescription/natures/nature").map[textContent]
			linkedResources = doc.selectByXPathQuery("/projectDescription/linkedResources/link").map[node |
				new Link(
					node.childNode("name").textContent,
					node.childNode("type").textContent,
					node.childNode("locationURI").textContent
				)
			]
		]
	}
}