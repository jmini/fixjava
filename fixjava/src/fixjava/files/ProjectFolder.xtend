package fixjava.files

import java.io.File

class ProjectFolder {
	@Property GroupFolder group
	@Property File root
	@Property int natureCount
	@Property boolean javaNature
	@Property boolean mavenNature
	@Property boolean useJUnit
}