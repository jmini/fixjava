package fixjava.files

import java.io.File
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

@ToString
class ProjectFolder {
	@Accessors GroupFolder group
	@Accessors File root
	@Accessors int natureCount
	@Accessors boolean javaNature
	@Accessors boolean mavenNature
	@Accessors boolean useJUnit
}