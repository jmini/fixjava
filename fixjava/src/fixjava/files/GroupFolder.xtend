package fixjava.files

import java.io.File
import java.util.List

/**
 * A {@link GroupFolder} represents a group of {@link ProjectFolder} representing a logical entity (like an application)
 */
class GroupFolder {
		@Property File root
		@Property String commonPrefix
		@Property int depth
		@Property List<ProjectFolder> projects
}