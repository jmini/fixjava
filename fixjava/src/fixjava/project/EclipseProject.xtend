package fixjava.project

import java.util.List

class EclipseProject {
	@Property String name
	@Property String comment
	@Property List<String> buildCommands
	@Property List<String> natures
	@Property List<Link> linkedResources
}
class Link {
	@Property String name
	@Property String type
	@Property String locationURI
}