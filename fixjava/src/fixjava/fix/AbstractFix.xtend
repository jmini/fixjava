package fixjava.fix

import fixjava.files.GroupFolder
import fixjava.config.IConfig

abstract class AbstractFix implements IFix {
	val protected IConfig config
	
	override executeFix(GroupFolder groupFolder) {
		groupFolder.projects.forEach[it.executeFix]
	}
	
	new (IConfig projectConfig) {
		config = projectConfig
	}
}