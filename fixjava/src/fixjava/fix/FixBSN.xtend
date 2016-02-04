package fixjava.fix

import com.google.common.base.Charsets
import com.google.common.io.Files
import fixjava.config.IConfig
import fixjava.files.GroupFolder
import fixjava.files.ProjectFolder
import java.io.File

/**
 * Fix the bundle symbolic name (and if there is a change, for java project the main package)
 */
class FixBSN extends AbstractRenameFix {
	
	String oldNamePrefix
	String newNamePrefix

	override executeFix(GroupFolder gf) {
		oldNamePrefix = gf.commonPrefix
		newNamePrefix = config.getBSNNewNamePrefix(gf)
			
		super.executeFix(gf)
		
		gf.commonPrefix = newNamePrefix
	}
	
	override executeFix(ProjectFolder pf) {
		if(pf.group.depth == config.BSNExpectedDepth) {
			val oldBSN = pf.root.name
			val newBSN = newNamePrefix + oldBSN.substring(oldNamePrefix.length)
			
//			println(oldBSN + " > "+ newBSN)
//			println(oldNamePrefix + " > "+ newNamePrefix)
//			println("---")
			
			if(newBSN != oldBSN) {
				//Move the root folder
				val newRoot = new File(pf.root.parentFile, newBSN)
				pf.root.moveTo(newRoot)
				pf.root = newRoot
				
				if(pf.javaNature) {
					newRoot.moveSrcFolder(oldBSN, newBSN)
				}
				
				val files = newRoot.findFiles
				files.forEach[
					val content = Files::toString(it, Charsets::UTF_8).replaceAll(oldNamePrefix, newNamePrefix)
					Files::write(content, it, Charsets::UTF_8)
				]
			}
		} else {
			System.err.println("ERROR: pf.group.depth ("+ pf.group.depth +") not not match configured BSNExpectedDepth ("+ config.BSNExpectedDepth +")")
		}
	}
	
	new (IConfig projectConfig) {
		super(projectConfig)
	}
}
