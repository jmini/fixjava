package fixjava.fix

import com.google.common.base.Charsets
import com.google.common.io.Files
import fixjava.config.IConfig
import fixjava.files.ProjectFolder
import java.io.File
import java.util.List
import java.util.Map.Entry

/**
 * Rename the java projects
 */
class FixRename extends AbstractRenameFix {
	
	//content of config.getRenameProjects (ordered in the order that needs to be processed).
	List<Entry<String, String>> renames
	
	override executeFix(ProjectFolder pf) {
		val files = pf.root.findFiles
		files.forEach[
			var content = Files::toString(it, Charsets::UTF_8)
			for(e : renames) {
				content = content.replaceAll(e.key, e.value)
			}
			Files::write(content, it, Charsets::UTF_8)
		]
		
		val oldName = pf.root.name
		if(config.renameProjects.containsKey(pf.root.name)) {
			val newName = config.renameProjects.get(pf.root.name)
			
			val oldRootFolder = pf.root
			val newRootFolder = new File(pf.root.parentFile, newName)
			oldRootFolder.moveTo(newRootFolder)
			
//			val projectFile = new File(newRootFolder, ".project")
//			if (projectFile.exists) {
//				val project = EclipseProjectReader.readEclipseProject(projectFile)
//				project.name = newName
//				EclipseProjectWritter.toFile(project, projectFile)
//			}
			newRootFolder.moveSrcFolder(oldName, newName)

		}
	}

	new (IConfig projectConfig) {
		super(projectConfig)
		renames = config.renameProjects.entrySet.sortWith[e1, e2 | 
			if(e1.key.startsWith(e2.key)) {
				return -1
			} else if(e2.key.startsWith(e1.key)) {
				return 1
			}
			e1.key.compareTo(e2.key)
		]
	}
}
