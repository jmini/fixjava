package fixjava.files

import java.io.File

class ProjectFolder {
	@Property File root
	@Property int depth
	@Property String commonPrefix
	@Property int natureCount
	@Property boolean javaNature
	@Property boolean mavenNature
}