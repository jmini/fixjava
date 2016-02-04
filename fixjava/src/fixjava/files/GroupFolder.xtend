package fixjava.files

import java.io.File
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.ToString

/**
 * A {@link GroupFolder} represents a group of {@link ProjectFolder} representing a logical entity (like an application)
 */
@ToString
class GroupFolder {
	@Accessors File root
	@Accessors String commonPrefix
	@Accessors int depth
	@Accessors List<ProjectFolder> projects
}